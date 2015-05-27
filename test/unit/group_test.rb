require_relative 'test_helper'

class GroupTest < ActiveSupport::TestCase
  fixtures :groups, :users, :profiles, :memberships, :sites,
    :castle_gates_keys

  def teardown
    Group.clear_key_cache # required! see CastleGates README
  end

  def test_memberships
    g = Group.create name: 'fruits'
    u = users(:blue)
    assert_equal 0, g.users.size, 'there should be no users'
    assert_raises RuntimeError, '<< should raise exception not allowed' do
      g.users << u
    end
    g.add_user! u
    g.add_user! users(:red)

    assert u.member_of?(g), 'user should be member of group'

    g.memberships.each do |m|
      m.destroy
    end
    g.reload
    assert_equal 0, g.users.size, 'there should be no users'
  end

  def test_missing_name
    g = Group.create
    assert !g.valid?, 'group with no name should not be valid'
  end

  def test_duplicate_name
    g1 = Group.create name: 'fruits'
    assert g1.valid?, 'group should be valid'

    g2 = Group.create name: 'fruits'
    assert g2.valid? == false, 'group should not be valid'
  end

  def test_try_to_create_group_with_same_name_as_user
    u = User.find(1)
    assert u.login, 'user should be valid'

    g = Group.create name: u.login
    assert g.valid? == false, 'group should not be valid'
    assert g.save == false, 'group should fail to save'
  end

  def test_cant_pester_private_group
    g = Group.create name: 'riseup'
    g.revoke_access! public: :view
    u = User.create login: 'user'

    assert u.may?(:pester, g) == false, 'should not be able to pester private group'
  end

  def test_can_pester_public_group
    g = Group.create name: 'riseup'
    g.grant_access! public: [:view, :pester]
    g.reload
    u = User.create login: 'user'

    assert u.may?(:pester, g) == true, 'should be able to pester private group'
  end

  def test_site_disabling_public_profiles_doesnt_affect_groups
    with_site(:local, profiles: ["private"]) do
      u = users(:red)
      g = groups(:animals)

      g.grant_access! public: :request_membership
      g.reload

      assert g.profiles.visible_by(u).public?
      assert g.has_access? :request_membership, u
    end
  end

  # disabled mocha test
  #def test_association_callbacks
  #  g = Group.create :name => 'callbacks'
  #  g.expects(:check_duplicate_memberships)
  #  u = users(:blue)
  #  g.add_user!(u)
  #end

  def test_committee_access
    g = groups(:public_group)
    assert_equal [groups(:public_committee)],
                 g.committees_for(users(:red)).sort_by{|c| c.id},
                 "should find 1 public committee"
    assert_equal [groups(:public_committee), groups(:private_committee)].sort_by{|c| c.id},
                 g.committees_for(users(:blue)).sort_by{|c| c.id},
                 "should find 2 committee with private access"
  end

  def test_councils
    group = groups(:rainbow)
    committee = groups(:cold)
    blue = users(:blue)
    red  = users(:red)

    assert_equal committee.parent, group
    assert blue.direct_member_of?(committee)
    assert !red.direct_member_of?(committee)

    assert red.may?(:admin, group)
    assert blue.may?(:admin, group)
    assert !group.has_a_council?

    assert_nothing_raised do
      group.add_council!(committee)
    end
    red.clear_cache
    blue.clear_cache
    assert !red.may?(:admin, group)
    assert blue.may?(:admin, group)
    assert group.has_a_council?
  end

  def test_name_change_increments_member_version
    group = groups(:true_levellers)
    user = users(:gerrard)

    # note: if the group has a committee, and the user is a member of that
    # committee, then the user's version will increment by more than one,
    # since the committees also experience a name change.
    assert_increases(user, :version) do
      assert_preserves(user, :updated_at) do
        group.name = 'diggers'
        group.save!
      end
    end
  end

  def test_associations
    User.current = users(:blue)
    assert check_associations(Group)
    User.current = nil
  end

  def test_alphabetized
    assert_equal Group.all.size, Group.alphabetized('').size

    # find numeric group names
    assert_equal 0, Group.alphabetized('#').size
    Group.create name: '1more'
    assert_equal 1, Group.alphabetized('#').size

    # case insensitive
    assert_equal Group.alphabetized('r').size, Group.alphabetized('R').size

    # nothing matches
    assert Group.alphabetized('z').empty?
  end

  def test_destroy
    g = Group.create name: 'fruits'
    g.add_user! users(:blue)
    g.add_user! users(:red)
    g.reload

    page = DiscussionPage.create! title: 'hello', user: users(:blue), owner: g
    assert_equal page.owner, g

    assert_difference 'Membership.count', -2 do
      g.destroy
    end

    assert_nil page.reload.owner_id

    red = users(:red)
    assert_nil GroupLostUserActivity.for_all(red).find(:first),
      "there should be no user left group message"
  end

  def test_avatar
    # must have GM installed
    if !GraphicsMagickTransmogrifier.new.available?
      puts "GraphicsMagick converter is not available. Either GraphicsMagick is not installed or it can not be started. Skipping GroupTest#test_avatar."
      return
    end

    group = nil
    assert_difference 'Avatar.count' do
      group = Group.create(
        name: 'groupwithavatar',
        avatar: Avatar.new(image_file: upload_avatar('image.png'))
      )
    end

    group.reload
    assert group.avatar.image_file_data.size > 0
    avatar_id = group.avatar.id

    group.avatar.image_file = upload_avatar('photo.jpg')
    group.avatar.save!
    group.save!
    group.reload
    assert group.avatar.image_file_data.size > 0
    assert_equal avatar_id, group.avatar.id

    group.avatar.image_file = upload_avatar('bee.jpg')
    group.avatar.save!
    group.reload
    assert_equal avatar_id, group.avatar.id
    assert group.avatar.image_file_data.size > 0

    assert_difference 'Avatar.count', -1 do
      group.destroy
    end

  end

  def test_group_hidden_by_default
    group = Group.create name: 'hidden-from-the-world'
    assert !users(:blue).may?(:view, group), "new groups should be hidden"
    group.migrate_permissions!
    assert !users(:blue).may?(:view, group), "new groups should remain hidden"
  end

  def test_migrate_public_group
    group = Group.create name: 'publicly-visible'
    assert group.valid?, "Failed to create group: #{group.errors.inspect}"

    # groups are hidden by default
    group.profiles.public.update_attributes! may_see: true

    assert !users(:blue).may?(:view, group),
      "initially blue should not be able to view the group"

    group.migrate_permissions!
    users(:blue).clear_access_cache

    assert users(:blue).may?(:view, group),
      "after migration blue should not be able to view the group"
  end

  def test_migrate_open_group
    group = Group.create name: 'hold-hands-and-join-the-circle'
    assert group.valid?

    group.profiles.public.update_attributes! membership_policy: Profile::MEMBERSHIP_POLICY[:open]

    assert ! users(:blue).may?(:join, group)

    group.migrate_permissions!
    users(:blue).clear_access_cache

    assert users(:blue).may?(:join, group)
  end

  def test_migrate_non_open_group
    group = Group.create name: 'du-kimst-hier-net-nei'
    assert group.valid?

    group.revoke_access! CastleGates::Holder[:public] => :request_membership

    group.profiles.public.update_attributes! may_request_membership: true

    assert ! users(:blue).may?(:join, group)
    assert ! users(:blue).may?(:request_membership, group)

    group.migrate_permissions!
    users(:blue).clear_access_cache

    assert ! users(:blue).may?(:join, group)
    assert users(:blue).may?(:request_membership, group)
  end

  def test_migrate_closed_group
    group = Group.create name: 'not-even-allowing-requests'
    assert group.valid?

    group.profiles.public.update_attributes! may_request_membership: true

    # defaults in effect
    assert ! users(:blue).may?(:join, group)
    assert ! users(:blue).may?(:request_membership, group)

    group.migrate_permissions!
    users(:blue).clear_access_cache

    # defaults overwritten to match profile setting
    assert ! users(:blue).may?(:join, group)
    assert users(:blue).may?(:request_membership, group)
  end

end
