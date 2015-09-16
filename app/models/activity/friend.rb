class Activity::Friend < Activity

  validates_format_of :subject_type, with: /User/
  validates_format_of :item_type, with: /User/
  validates_presence_of :subject_id
  validates_presence_of :item_id

  alias_attr :user,       :subject
  alias_attr :other_user, :item

  before_create :set_access
  after_create :create_twin

  def set_access
    # this has a weird side effect of creating public and private
    # profiles if they don't already exist.
    if user.access? public: :see_contacts
      self.access = Activity::PUBLIC
    elsif user.access? user.associated(:friends) => :see_contacts
      self.access = Activity::DEFAULT
    else
      self.access = Activity::PRIVATE
    end
  end

  def create_twin
    twin.first_or_create do |other|
      other.key = self.key
    end
  end

  def description(view=nil)
    I18n.t(:activity_contact_created,
            user: user_span(:user),
            other_user: user_span(:other_user))
  end

  # Warning: Do not use self.class or even Activity::Friend here...
  # Why? It seems the scope of self is kept in that case.
  # So activity.twin.twin would always return nil because it tries to
  # fullfill both conditions (those for the twin and for the twin of that twin)
  # at the same time.
  # UPGRADE: Check if this is fixed
  def twin
    Activity.where type: 'Friend',
      subject_id: item_id, subject_type: 'User',
      item_id: subject_id, item_type: 'User'
  end

  def icon
    'user_add'
  end

end

