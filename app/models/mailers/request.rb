module Mailers::Request

  #
  # Send an email letting the user know that a page has been 'sent' to them.
  #

  def request_to_join_us(request, options)
    # setup(options)
    # accept_link = url_for(:controller => 'requests', :action => 'accept',
    #    :path => [request.code, request.email.gsub('@','_at_')])
    # group_home = url_for(:controller => request.group.name) # tricky way to get url /groupname

    # recipients request.email
    # subject I18n.t(:group_invite_subject, :group => request.group.display_name)
    # body({ :from_user => @current_user, :group => request.group, :link => accept_link,
    #    :group_home => group_home })
  end

  def request_to_destroy_our_group(request, user)
    # @group = request.group
    # @user = user
    # @created_by = request.created_by

    # # this is shitty
    # email_sender = @site.try.email_sender ? @site.email_sender : Conf.email_sender
    # domain = @site.try.domain ? @site.domain : Conf.domain
    # @from = email_sender.gsub('$current_host', domain)

    # @recipients = "#{user.email}"

    # @subject = I18n.t(:request_to_destroy_our_group_description,
    #                 :group => @group.full_name,
    #                 :group_type => @group.group_type.downcase,
    #                 :user => @created_by.display_name)

    # @request_link = url_for(:controller => 'me/requests/', :id => request.id)
    # @body[:user] = @created_by
    # @body[:group] = @group
  end

end

