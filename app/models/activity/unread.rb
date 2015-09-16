class Activity::Unread < Activity

  validates_format_of :subject_type, with: /User/
  validates_presence_of :subject_id
  validate :has_unread_count, on: :create

  alias_attr :user, :subject
  alias_attr :author, :item
  alias_attr :unread_count, :key

  def has_unread_count
    unless unread_count > 0
      errors.add("unread_count", "must be greater than zero")
    end
  end

  protected

  before_validation :set_access, on: :create
  def set_access
    self.access = Activity::PRIVATE
    self.unread_count = user.relationships.sum('unread_count') || 0
  end

  # We want to delete the other Activity::Unread even if we don't pass
  # validations, because if there are no unread messages, we want no
  # Activity.
  before_validation :destroy_twins, on: :create
  def destroy_twins
    self.class.destroy_all 'subject_id = %s' % user.id
  end

  public

  def avatar
    unread_count == 1 ? author : user
  end

  def description(view)
    if unread_count == 1
      str = I18n.t(:activity_unread_singular)
      if author
        link = view.send(:my_private_message_path, author)
      else
        link = view.send(:my_private_messages_path)
      end
    else
      str = I18n.t(:activity_unread, count: unread_count)
      link = view.send(:my_private_messages_path)
    end

    str.sub(/\[(.*)\]/) do |match|
      view.link_to($1, link)
    end
  end

  def created_at
    nil
  end

  def icon
    'page_message'
  end

end
