#
# Module that extends Group behavior.
#
# Handles all the group <> user relationships
#
module GroupExtension::Users
  # large groups will be ignored when calculating peers.
  LARGE_GROUP_SIZE=50

  def self.included(base)
    base.instance_eval do

      before_destroy :destroy_memberships
#      before_create :set_created_by

      has_many :memberships, before_add: :check_duplicate_memberships

      has_many :users, through: :memberships do
        def <<(*dummy)
          raise "don't call << on group.users"
        end
        def delete(*records)
          raise "don't call delete on group.users"
        end
        def most_recently_active(options={})
          order('memberships.visited_at DESC')
        end
        # UPGRADE: This is a workaround for the lack of declaring a
        # query DISTINCT and having that applied to the final query.
        # it won't be needed anymore as soon as .distinct can be used
        # with rails 4.0
        def with_access(access)
          super(access).only_select("DISTINCT users.*")
        end
      end

      # tmp hack until we have a better viewing system in place.
      scope :most_visits, joins(:memberships).
        group('groups.id').
        order('count(memberships.total_visits) DESC')

      scope :recent_visits, joins(:memberships).
        group('groups.id').
        order('memberships.visited_at DESC')

      def self.with_admin(user)
        where("groups.id IN (?)", user.admin_for_group_ids)
      end

      scope :large, joins(:memberships).
        group('groups.id').
        select('groups.*').
        having("count(memberships.id) > #{LARGE_GROUP_SIZE}")

    end
  end

  # commented out... removing a council member from a group is no big deal,
  # they can still just add themselves back. -e
  #
  #def users_allowed_to_vote_on_removing(user)
  #  # only council members can vote on removing council members
  #  if self.has_a_council? and user.may?(:admin, self)
  #    return self.council.users
  #  else
  #    return self.users
  #  end
  #end

  #
  # timestamp of the last visit of a user
  #
  def last_visit_of(user)
    memberships.where(user_id: user).first.try.visited_at
  end

  def user_ids
    @user_ids ||= memberships.collect{|m|m.user_id}
  end

  def all_users
    users
  end

  # association callback
  def check_duplicate_memberships(membership)
    membership.user.check_duplicate_memberships(membership)
  end

  def relationship_to(user)
    relationships_to(user).first
  end
  def relationships_to(user)
    return [:stranger] unless user
    return [:stranger] if user.is_a? UnauthenticatedUser

    @relationships_to_user_cache ||= {}
    @relationships_to_user_cache[user.login] ||= get_relationships_to(user)
    @relationships_to_user_cache[user.login].dup
  end

  def get_relationships_to(user)
    ret = []
#   ret << :admin    if ...
    ret << :member   if user.member_of?(self)
#   ret << :peer     if ...
    ret << :stranger
    ret
  end

  #
  # this is the ONLY way to add users to a group.
  # all other methods will not work.
  #
  def add_user!(user)
    self.memberships.create! user: user
    user.update_membership_cache
    user.clear_peer_cache_of_my_peers
    clear_key_cache

    @user_ids = nil
    self.increment!(:version)
  end

  #
  # this is the ONLY way to remove users from a group.
  # all other methods will not work.
  #
  def remove_user!(user)
    membership = self.memberships.find_by_user_id(user.id)
    raise ErrorMessage.new('no such membership') unless membership

    user.clear_peer_cache_of_my_peers
    membership.destroy
    user.update_membership_cache
    clear_key_cache

    @user_ids = nil
    self.increment!(:version)

    # remove user from all the groups committees
    self.committees.each do |committe|
      committe.remove_user!(user) unless committe.users.find_by_id(user.id).blank?
    end
  end

  def open_membership?
    self.profiles.public.membership_policy_is? :open
  end

  def single_user?
    self.users.count == 1
  end

  protected

  def destroy_memberships
    user_names = []
    self.memberships.each do |membership|
      user = membership.user
      user_names << user.name
      membership.skip_destroy_notification = true
      user.clear_peer_cache_of_my_peers
      membership.destroy
      user.update_membership_cache
    end
    self.increment!(:version)
  end

  def set_created_by
    self.created_by ||= User.current
  end

# maps a user <-> group relationship to user <-> language
#  def in_user_terms(relationship)
#    case relationship
#      when :member;   'friend'
#      when :ally;     'peer'
#      else; relationship.to_s
#    end
#  end

end

