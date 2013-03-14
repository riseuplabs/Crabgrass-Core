##
## PAGE CREATION
##

module Common::Page::CreationHelper

#  protected

#  #
#  # new_page_path is used for showing the selection of page types.
#  #
#  # page_creation_path is used for linking to the actual controller that handles creation
#  # for a particular page type. It might be the default page creation controller (pages/create),
#  # or it could be a custom controller.
#  #
#  def page_creation_path(page_class)
#    controller = page_class.definition.creation_controller || 'pages/create'
#    url_for(:controller => controller, :action => 'new', :type => page_class.url, :group => params[:group_id])
#  end

#  #
#  # generates the links used to choose a page type when creating a page
#  #
#  def page_creation_links
#    tree_of_page_types(:simple => true).collect do |grouping|
#      content_tag(:h2, grouping[:display]) + content_tag(:div, :class => 'hover') do
#        grouping[:pages].collect do |page_class|
#          link_text = "<b>#{page_class.class_display_name}</b><br/>#{page_class.class_description}"
#          link_to(link_text, page_creation_path(page_class), {:class => "p icon top #{page_class.icon}_16"})
#        end
#      end
#    end
#  end

#  # TODO: wtf? seems like a ton duplication here.

#  # returns a link to the create action for the type given.
#  def link_to_create(type)
#    if type == :groups
#      if may_create_group?
#        link_to(I18n.t(:create_a_group).upcase, groups_url(:action => 'new'))
#      end
#    elsif type == :networks
#      if may_create_network?
#        link_to(I18n.t(:create_a_network).upcase, networks_url(:action => 'new'))
#      end
#    end
#  end

#  ## Link to the action for the form to create a page of a particular type.
#  def create_page_url(page_class=nil, options={})
#    if page_class
#      controller = page_class.controller
#      id = page_class.param_id
#      "/#{controller}/create/#{id}" + build_query_string(options)
#    else
#      new_me_page_url
#    end
#  end

#  def create_page_link(group=nil, options={})
#    if group
#      url = new_group_page_url(group) if may_edit_group?
#    else
#      url = new_me_page_url if may_create_pages?
#    end
#    return unless url
#    text = I18n.t(:contribute_content_link).upcase


#    content_tag(:div,
#        link_to(text, url ),
#      :id => 'contribute'
#    )
#  end

#  #  group -- what group we are creating the page for
#  #  type -- the page class we are creating
#  def typed_create_page_link(page_type, group=nil)
#    link_to I18n.t(:create_a_new_thing, :thing => page_type.class_display_name) + ARROW, create_page_url(page_type, :group => @group)
#  end

##  def create_page_link(text,options={})
##    url = url_for :controller => '/pages', :action => 'create'
##    ret = ""
##    ret += "<form class='link' method='post' action='#{url}'>"
##    options.each do |key,value|
##      ret += hidden_field_tag(key,value)
##    end
##    ret += link_to_function(text, 'event.target.parentNode.submit()')
##    ret += "</form>"
##    #link_to(text, {:controller => '/pages', :action => 'create'}.merge(options), :method => :post)
##  end


#  #
#  #
#  # NEW UI
#  #
#  # Elements Used in the Layouts
#  #
#  # checkbox for selecting the page in a list of pages.
#  def checkbox_for(page)
#    # check_box('page_checked', page.id, {:class => 'page_check'}, 'checked', '')
#    check_box_tag 'pages[]', page.id, false, :id =>"page_checkbox_#{page.id}", :class => 'page_check_box'
#  end

#  def summary_for(page)
#    klass = page.cover.nil? ? '' : 'cover'
#    text_with_more(page.summary, :p, :class => klass, :more_url=> page_url(page), :length => 300)
#  end

#  def owner_image(page, options={})
#    return unless page.owner
#    display_name = page.owner.respond_to?(:display_name) ? page.owner.display_name : ""
#    url = url_for_entity(page.owner)
#    img_tag = avatar_for page.owner, 'small'
#    if options[:with_tooltip]
#      owner_entity = I18n.t((page.owner.is_a?(Group) ? 'group' : 'user').to_sym).downcase
#      details = I18n.t(:page_owned_by, :title => page.title, :entity => owner_entity, :name => display_name)
#      render :partial => 'pages/page_details', :locals => {:url => url, :img_tag => img_tag, :details => details}
#    else
#      link_to(img_tag, url, :class => 'imglink tooltip', :title => display_name)
#    end
#  end

#  def page_html_attributes(page)
#    icon = page.icon || :page_text_blue

#    classes = %w(small_icon)
#    classes << "#{icon}_16"
#    classes << 'unread' if page_is_unread(page)
#    classes << 'cover' unless page.cover.nil?
#    { :class => classes.join(' ') }
#  end

#  # we use a cached field from the user_participation and fall
#  # back to fetching the user_participation again.
#  def page_is_unread(page)
#    if page.flag[:user_participation]
#      !page.flag[:user_participation].viewed
#    else
#      page.unread_by?(current_user)
#    end
#  end

#  def section_html_attributes(page)
#    classes = %w(pages-info)
#    classes << 'unread' if page_is_unread(page)
#    { :class => classes.join(' ') }
#  end

#  def notices_for(page)
#    notices = page.flag[:user_participation].try.notice
#    if notices.any?
#      render :partial=>'pages/notice', :collection => notices
#    end
#  end

#  def page_notice_message(notice)
#    sender = User.find_by_login notice[:user_login]
#    date = friendly_date notice[:time]
#    html = I18n.t(:page_notice_message, :user => link_to_user(sender), :date => date)
#    if notice[:message].present?
#      notice_message_html = ":<br/> &ldquo;<i>%s</i>&rdquo;" % h(notice[:message])
#      html += ' ' + I18n.t(:notice_with_message, :message => notice_message_html)
#    end
#    html
#  end

end
