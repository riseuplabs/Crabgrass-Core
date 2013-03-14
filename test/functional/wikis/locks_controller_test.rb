require_relative '../test_helper'

class Wikis::LocksControllerTest < ActionController::TestCase

  def setup
    @user  = FactoryGirl.create(:user)
    @group  = FactoryGirl.create(:group)
    @wiki = Wiki.create :group => @group
    @wiki.lock!(:document, @user)
  end

  def test_destroy_own_lock
    login_as @user
    delete :destroy, :wiki_id => @wiki.id
    assert_nil @wiki.reload.section_edited_by(@user)
  end

  def test_cannot_destroy_other_peoples_locks
    login_as FactoryGirl.create(:user)
    delete :destroy, :wiki_id => @wiki.id
    assert_equal 'permission denied', @response.body
    assert_equal :document, @wiki.reload.section_edited_by(@user)
  end

  def test_cannot_destroy_locks_when_logged_out
    delete :destroy, :wiki_id => @wiki.id
    assert_equal 'permission denied', @response.body
    assert_equal :document, @wiki.reload.section_edited_by(@user)
  end
end
