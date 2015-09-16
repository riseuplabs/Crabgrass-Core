require_relative 'test_helper'

class Activity::Test < ActiveSupport::TestCase

  def setup
    @joe = FactoryGirl.create(:user)
    @ann = FactoryGirl.create(:user)
    @group = FactoryGirl.create(:group)
    @group.add_user! @joe
    @group.add_user! @ann
    @joe.reload
    @ann.reload
  end

  def test_contact
    assert_difference 'Activity.count', 2 do
      Activity::Friend.create! user: @joe, other_user: @ann
    end
    act = Activity::Friend.for_me(@joe).find(:first)
    assert act, 'there should be a friend activity created'
    assert_equal @joe, act.user
    assert_equal @ann, act.other_user
  end

  def test_group_created
    act = Activity::GroupCreated.new group: @group, user: @ann
    assert_activity_for_user_group(act, @ann, @group)

    act = Activity::UserCreatedGroup.new group: @group, user: @ann
    assert_activity_for_user_group(act, @ann, @group)
  end

  def test_create_membership
    ruth = FactoryGirl.create(:user)
    @group.add_user!(ruth)
    Tracking::Action.track :create_membership, group: @group, user: ruth

    assert_nil Activity::UserJoinedGroup.for_all(@ann).find_by_subject_id(ruth.id),
      "The new peers don't get UserJoinedGroupActivities."

    act = Activity::GroupGainedUser.for_all(@ann).last
    assert_equal @group.id, act.group.id,
      "New peers should get GroupGainedUserActivities."

    act = Activity::GroupGainedUser.for_group(@group, ruth).last
    assert_equal Activity::GroupGainedUser, act.class
    assert_equal @group.id, act.group.id

    # users own activity should always show up:
    act = Activity::UserJoinedGroup.for_all(ruth).last
    assert_equal @group.id, act.group.id
  end


  ##
  ## Remove the user
  ##
  def test_destroy_membership
    @group.remove_user!(@joe)
    Tracking::Action.track :destroy_membership, group: @group, user: @joe

    act = Activity::GroupLostUser.for_all(@ann).last
    assert_activity_for_user_group(act, @joe, @group)

    act = Activity::GroupLostUser.for_group(@group, @ann).last
    assert_activity_for_user_group(act, @joe, @group)

    act = Activity::UserLeftGroup.for_all(@joe).last
    assert_activity_for_user_group(act, @joe, @group)
  end

  def test_deleted_subject
    @joe.add_contact!(@ann, :friend)
    Tracking::Action.track :create_friendship, user: @joe, other_user: @ann
    act = Activity::Friend.for_me(@joe).find(:first)
    former_name = @ann.name
    @ann.destroy

    assert act.reload, 'there should still be a friend activity'
    assert_equal nil, act.other_user
    assert_equal former_name, act.other_user_name
    assert_equal "<user>#{former_name}</user>",
      act.user_span(:other_user)
  end

  def test_avatar
    new_group = FactoryGirl.create(:group)

    @joe.add_contact!(@ann, :friend)
    Tracking::Action.track :create_friendship, user: @joe, other_user: @ann
    @joe.send_message_to!(@ann, "hi @ann")
    new_group.add_user!(@joe)
    Tracking::Action.track :create_membership, group: new_group, user: @joe

    friend_act = Activity::Friend.find_by_subject_id(@joe.id)
    user_joined_act = Activity::UserJoinedGroup.find_by_subject_id(@joe.id)
    group_gained_act = Activity::GroupGainedUser.find_by_subject_id(new_group.id)
    post_act = Activity::MessageSent.find_by_subject_id(@ann.id)
    # we do not create PrivatePost Activities anymore
    assert_nil post_act


    # the person doing the thing should be the avatar for it
    # disregarding whatever is the subject (in the gramatical/language sense) of the activity
    assert_equal @joe, friend_act.avatar
    assert_equal @joe, user_joined_act.avatar
    assert_equal @joe, group_gained_act.avatar
    #assert_equal @joe, post_act.avatar
  end

  def test_associations
    assert check_associations(Activity)
  end

  def assert_activity_for_user_group(act, user, group)
    assert_equal group.id, act.group.id
    assert_equal user.id, act.user.id
    assert_in_description(act, group)
    assert_in_description(act, user)
    assert_not_nil act.icon
  end

  def assert_in_description(act, thing)
    assert_match thing.name, act.description
  end

end

