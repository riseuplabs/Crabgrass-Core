require File.dirname(__FILE__) + '/../../test_helper'

class Groups::MembershipsControllerTest < ActionController::TestCase

  def setup
    @user  = FactoryGirl.create(:user)
    @group  = FactoryGirl.create(:group)
    @group.add_user!(@user)
  end

  def test_index
    login_as @user
    assert_permission :may_list_memberships? do
      get :index, :group_id => @group.to_param
    end
    assert_response :success
  end

  def test_destroy
    @council = FactoryGirl.create(:committee)
    @group.add_council! @council
    @council.add_user! @user
    other_user  = FactoryGirl.create(:user)
    @group.add_user! other_user
    membership = @group.memberships.find_by_user_id(other_user.id)
    login_as @user
    assert_permission :may_destroy_membership? do
      delete :destroy, :group_id => @group.to_param, :id => membership.id
    end
    assert_response :success
  end

end
