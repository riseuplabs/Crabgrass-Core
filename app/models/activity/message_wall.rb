class Activity::MessageWall < Activity
  include ActionView::Helpers::TagHelper

  validates_format_of :subject_type, with: /User/
  validates_format_of :item_type, with: /User/
  validates_presence_of :subject_id
  validates_presence_of :item_id
  validates_presence_of :extra

  belongs_to :post, foreign_key: :related_id

  serialize :extra

  alias_attr :user,     :subject
  alias_attr :author,   :item
  alias_attr :avatar,   :item
  alias_attr :post_id,  :related_id

  # This is likely created via Activity.track with controller options.
  # The controller options like user may not be what we want...
  # We only trust the post.
  before_validation :extract_attrs_from_post
  def extract_attrs_from_post
    return true unless post
    self.extra = {}
    self.extra[:snippet] = GreenCloth.new(post.body[0..140], 'page', [:lite_mode]).to_html
    self.extra[:snippet] += '...' if post.body.length > 140
    self.extra[:type] = 'status' if post.is_a? StatusPost
    self.user = post.recipient
    self.author = post.user
    self.access = 2 if post.default?
  end

  before_create :set_access
  def set_access
    # all content on the wall is public anyway
    # except status posts
    self.access ||= Activity::PUBLIC
  end

  def description(view=nil)
    if extra[:type] == "status"
      txt = '%{user} %{message}' % {user: user_span(:author), message: extra[:snippet]}
    elsif user_id != author_id
      author_html = user_span(:author)
      user_html = user_span(:user)
      message_html = content_tag(:span, extra[:snippet],class: 'message')

      txt = I18n.t(:activity_wall_message, user: user_html, author: author_html, message: message_html)
    else
      author_html = user_span(:author)
      message_html = content_tag(:span,extra[:snippet], class: 'message')
      txt = I18n.t(:activity_message, author: author_html, message: message_html)
    end
#    if txt[-3..-1] == '...'
#      @link = content_tag(:a, I18n.t(:see_more_link), :href => "/messages/#{user_id}/show/#{post_id}")
#    else
#      @link = content_tag(:a, I18n.t(:details_link), :href => "/messages/#{user_id}/show/#{post_id}")
#    end
    return txt
  end

  def link
    if user == User.current
      {controller: '/me/public_messages', id: post_id, action: 'show'}
    else
      nil
      # we currently have no single message view it seems
      #{:controller => '/people/messages', :person_id => user, :id => post_id, :action => 'show'}
    end
  end

  def icon
    if extra[:type] == 'status'
      'lightning'
    else
      'comment'
    end
  end

  def style
    url = '/avatars/%s/%s.jpg?%s' % [author.try.avatar_id||0, 'tiny', author.try.updated_at.to_i]
    "background-image: url(#{url});"
  end

end

