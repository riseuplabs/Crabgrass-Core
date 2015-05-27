#
#     group_members GET    /groups/:group_id/members          {:action=>"index"}
#                   DELETE /groups/:group_id/members/:id      {:action=>"destroy"}
#                   POST   /groups/:group_id/members/:id?user_name=x      {:action=>"create"}
#

class Groups::MembershipsController < Groups::BaseController

  guard index: :may_list_memberships?,
        destroy: :may_destroy_membership?,
        create: :may_create_membership?

  #
  # list all the memberships
  #
  def index
    if federation_view?
      @memberships = @group.federatings.paginate(pagination_params)
    else
      @memberships = @group.memberships.paginate(pagination_params)
    end
  end

  #
  # immediately destroy a membership
  #
  def destroy
    # memberships must be destroyed via group.remove_user!
    @membership.group.remove_user! @membership.user
  end

  #
  # add someone directly to a group
  #
  def create
    raise_not_found unless @group && @user
    @group.add_user! @user
    index # load @memberships
    success
  end

  protected

  def fetch_group
    super
    if action?(:destroy)
      if federation_view?
        @membership = @group.federatings.find(params[:id])
      else
        @membership = @group.memberships.find(params[:id])
      end
    elsif action?(:create)
      if params[:user_name]
        @user = User.find_by_login(params[:user_name])
      end
    end
  end

  def federation_view?
    params[:view] == 'groups'
  end
  helper_method :federation_view?

end

