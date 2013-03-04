require File.dirname(__FILE__) + '/../../test_helper'

class Wikis::WikisControllerTest < ActionController::TestCase

  def setup
    @user  = FactoryGirl.create(:user)
    @group  = FactoryGirl.create(:group)
    @group.add_user!(@user)
    @wiki = @group.profiles.public.create_wiki :body => 'init'
  end


  def test_edit
    login_as @user
    assert_permission :may_edit_wiki? do
      xhr :get, :edit, :id => @wiki.id
    end
    assert_response :success
    assert_template 'wikis/wikis/edit'
    assert_equal 'text/javascript', @response.content_type
    assert_equal @group, assigns(:group)
    assert_equal @wiki, assigns['wiki']
    assert_equal @group, assigns['context'].entity
    assert_equal @user, @wiki.reload.locker_of(:document)
  end

  def test_edit_locked
    other_user  = FactoryGirl.create(:user)
    @wiki.lock! :document, other_user
    login_as @user
    assert_permission :may_edit_wiki? do
      xhr :get, :edit, :id => @wiki.id
    end
    assert_response :success
    assert_template 'wikis/wikis/locked'
    assert_equal 'text/javascript', @response.content_type
    assert_equal other_user, @wiki.locker_of(:document)
    assert_equal @wiki, assigns['wiki']
  end

  def test_update
    login_as @user
    assert_permission :may_edit_wiki? do
      xhr :post, :update,
        :id => @wiki.id,
        :wiki => {:body => '*updated*', :version => 1}
    end
    assert_response :redirect
    assert_redirected_to group_home_url(@group, :wiki_id => @wiki.id)
    assert_equal "<p><strong>updated</strong></p>", @wiki.reload.body_html
  end

  def test_show_private_group_wiki
    @priv = @group.profiles.private.create_wiki :body => 'init'
    login_as @user
    assert_permission :may_show_wiki? do
      xhr :get, :show, :id => @priv.id
    end
    assert_response :success
    assert_equal @priv, assigns['wiki']
  end

  def test_show_public_group_wiki_to_stranger
    assert_permission :may_show_wiki? do
      xhr :get, :show, :id => @wiki.id
    end
    assert_response :success
    assert_equal @wiki, assigns['wiki']
  end

  def test_do_not_show_private_group_wiki_to_stranger
    @priv = @group.profiles.private.create_wiki :body => 'private'
    assert_permission(:may_show_wiki?, false) do
      xhr :get, :show, :id => @priv.id
    end
  end

end
