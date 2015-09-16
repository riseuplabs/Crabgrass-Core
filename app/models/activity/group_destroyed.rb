class Activity::GroupDestroyed < Activity

  validates_format_of :subject_type, with: /User/
  validates_presence_of :subject_id
  validates_presence_of :extra

  alias_attr :recipient,     :subject
  alias_attr :destroyed_by,  :item
  alias_attr :groupname,     :extra

  def description(view=nil)
    I18n.t(:activity_group_destroyed,
       user: user_span(:destroyed_by),
       group: groupname)
  end

  def icon
    'minus'
  end

end

