#
# A contact request
#
# creator: user wanting a friend
# recipient: potential friend
# requestable: nil
#
#
class RequestToFriend < Request

  validates_format_of :recipient_type, :with => /User/
  validate_on_create :no_friendship_yet

  def no_friendship_yet
    if Friendship.find_by_user_id_and_contact_id(created_by_id, recipient_id)
      errors.add_to_base('Friendship already exists')
    end
  end

  #
  # returns existing friend request, if any.
  # requires: {:from => x, :to => y}
  #
  def self.existing(options)
    pending.created_by(options[:from]).to_user(options[:to]).first
  end

  def requestable_required?() false end

  def may_create?(user)
    true
  end

  def may_destroy?(user)
    user == recipient or user == created_by
  end

  def may_approve?(user)
    recipient == user
  end

  def may_view?(user)
    user == recipient or may_approve?(user)
  end

  def after_approval
    recipient.add_contact!(created_by, :friend)
  end

  def description
    [:request_to_friend_description, {:user => user_span(created_by), :other_user => user_span(recipient)}]
  end

  def short_description
    [:request_to_friend_short, {:user => user_span(created_by), :other_user => user_span(recipient)}]
  end

end
