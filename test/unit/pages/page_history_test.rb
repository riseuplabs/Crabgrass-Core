require 'test_helper'

# WARNING:
# this test are not isolated since their are using instance objects that for example create a page
# involve create an user participation and that makes create a page_history object, so when you read
# the tests some counts for example seems to not have sense, but this is because of that already created data.
class PageHistoryTest < ActiveSupport::TestCase

  def setup
    Page.delete_all
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    @user = FactoryGirl.create(:user, :login => "pepe")
    User.current = @user

    @page = FactoryGirl.create(:page, :owner => @user)

    @site = FactoryGirl.create(:site, :domain => "crabgrass.org",
                               :title => "Crabgrass Social Network",
                               :email_sender => "robot@$current_host",
                               :default => true,
                               :name => 'cg'
                              )
    enable_site_testing 'cg'
  end

  def teardown
    Page.delete_all
    User.delete_all
    User.current = nil
    disable_site_testing
  end

  def test_validations
    assert_raise ActiveRecord::RecordInvalid do PageHistory.create!(:user => nil, :page => nil) end
    assert_raise ActiveRecord::RecordInvalid do PageHistory.create!(:user => @user, :page => nil) end
    assert_raise ActiveRecord::RecordInvalid do PageHistory.create!(:user => nil, :page => @page) end
  end

  def test_associations
    page_history = PageHistory.create!(:user => @user, :page => @page)
    assert_equal @user, page_history.user
    assert_kind_of Page, page_history.page
  end

  def test_set_update_at_of_the_page
    post = FactoryGirl.create(:post)
    user = FactoryGirl.create(:user)
    group = FactoryGirl.create(:group)

    page = FactoryGirl.create(:page, :created_at => 3.months.ago, :updated_at => 2.months.ago)
    PageHistory.create!(:user => @user, :page => page)
    assert_not_change_updated_at page

    page = FactoryGirl.create(:page)
    Page.update_all(["created_at = ?, updated_at = ?", 3.months.ago, 2.months.ago], ["id = ?", page.id])
    assert_change_updated_at page, PageHistory::PageCreated.create!(:user => @user, :page => page)

    page = FactoryGirl.create(:page)
    Page.update_all(["created_at = ?, updated_at = ?", 3.months.ago, 2.months.ago], ["id = ?", page.id])
    assert_change_updated_at page, PageHistory::UpdatedContent.create!(:user => @user, :page => page)

    page = FactoryGirl.create(:page)
    Page.update_all(["created_at = ?, updated_at = ?", 3.months.ago, 2.months.ago], ["id = ?", page.id])
    assert_change_updated_at page, PageHistory::ChangeTitle.create!(:user => @user, :page => page)

    page = FactoryGirl.create(:page)
    Page.update_all(["created_at = ?, updated_at = ?", 3.months.ago, 2.months.ago], ["id = ?", page.id])
    assert_change_updated_at page, PageHistory::Deleted.create!(:user => @user, :page => page)

    page = FactoryGirl.create(:page)
    Page.update_all(["created_at = ?, updated_at = ?", 3.months.ago, 2.months.ago], ["id = ?", page.id])
    assert_change_updated_at page, PageHistory::AddComment.create!(:user => @user, :page => page, :object => post)

    page = FactoryGirl.create(:page)
    Page.update_all(["created_at = ?, updated_at = ?", 3.months.ago, 2.months.ago], ["id = ?", page.id])
    assert_change_updated_at page, PageHistory::UpdateComment.create!(:user => @user, :page => page, :object => post)

    page = FactoryGirl.create(:page)
    Page.update_all(["created_at = ?, updated_at = ?", 3.months.ago, 2.months.ago], ["id = ?", page.id])
    assert_change_updated_at page, PageHistory::DestroyComment.create!(:user => @user, :page => page, :object => post)

    page = FactoryGirl.create(:page)
    Page.update_all(["created_at = ?, updated_at = ?", 3.months.ago, 2.months.ago], ["id = ?", page.id])
    assert_change_updated_at page, PageHistory::GrantGroupFullAccess.create!(:user => @user, :page => page, :object => group)

    page = FactoryGirl.create(:page)
    Page.update_all(["created_at = ?, updated_at = ?", 3.months.ago, 2.months.ago], ["id = ?", page.id])
    assert_change_updated_at page, PageHistory::GrantGroupWriteAccess.create!(:user => @user, :page => page, :object => group)

    page = FactoryGirl.create(:page)
    Page.update_all(["created_at = ?, updated_at = ?", 3.months.ago, 2.months.ago], ["id = ?", page.id])
    assert_change_updated_at page, PageHistory::GrantGroupReadAccess.create!(:user => @user, :page => page, :object => group)

    page = FactoryGirl.create(:page)
    Page.update_all(["created_at = ?, updated_at = ?", 3.months.ago, 2.months.ago], ["id = ?", page.id])
    assert_change_updated_at page, PageHistory::RevokedGroupAccess.create!(:user => @user, :page => page, :object => group)

    page = FactoryGirl.create(:page)
    Page.update_all(["created_at = ?, updated_at = ?", 3.months.ago, 2.months.ago], ["id = ?", page.id])
    assert_change_updated_at page, PageHistory::GrantUserFullAccess.create!(:user => @user, :page => page, :object => user)

    page = FactoryGirl.create(:page)
    Page.update_all(["created_at = ?, updated_at = ?", 3.months.ago, 2.months.ago], ["id = ?", page.id])
    assert_change_updated_at page, PageHistory::GrantUserWriteAccess.create!(:user => @user, :page => page, :object => user)

    page = FactoryGirl.create(:page)
    Page.update_all(["created_at = ?, updated_at = ?", 3.months.ago, 2.months.ago], ["id = ?", page.id])
    assert_change_updated_at page, PageHistory::GrantUserReadAccess.create!(:user => @user, :page => page, :object => user)

    page = FactoryGirl.create(:page)
    Page.update_all(["created_at = ?, updated_at = ?", 3.months.ago, 2.months.ago], ["id = ?", page.id])
    assert_change_updated_at page, PageHistory::RevokedUserAccess.create!(:user => @user, :page => page, :object => user)
  end

  def test_change_title_saves_old_and_new_value
    page = FactoryGirl.create(:page, :title => "Bad title")
    page.update_attribute :title, "Nice title"
    page_history = PageHistory::ChangeTitle.find :first, :conditions => {:page_id => page.id}
    assert_equal "Bad title", page_history.details[:from]
    assert_equal "Nice title", page_history.details[:to]
  end

  def test_recipients_for_digest_notifications
    user   = FactoryGirl.create(:user, :login => "user", :receive_notifications => nil)
    user_a = FactoryGirl.create(:user, :login => "user_a", :receive_notifications => "Single")
    user_b = FactoryGirl.create(:user, :login => "user_b", :receive_notifications => "Digest")
    user_c = FactoryGirl.create(:user, :login => "user_c", :receive_notifications => "Digest")

    FactoryGirl.build(:user_participation, :page => @page, :user => user_a, :watch => true).save!
    FactoryGirl.build(:user_participation, :page => @page, :user => user_b, :watch => true).save!
    FactoryGirl.build(:user_participation, :page => @page, :user => user_c, :watch => true).save!

    assert_equal 2, PageHistory.recipients_for_digest_notifications(@page).count

    # this should not receive notifications because he has it disabled
    assert !PageHistory.recipients_for_digest_notifications(@page).include?(user)

    # this should not receive notifications because he has Single enabled
    assert !PageHistory.recipients_for_digest_notifications(@page).include?(user_a)

    # this should receibe notifications because he has it enabled
    assert PageHistory.recipients_for_digest_notifications(@page).include?(user_b)
    assert PageHistory.recipients_for_digest_notifications(@page).include?(user_c)
  end

  def test_send_digest_pending_notifications
    PageHistory.delete_all
    user_a = FactoryGirl.create(:user, :receive_notifications => "Digest")
    user_b = FactoryGirl.create(:user, :receive_notifications => "Digest")
    user_c = FactoryGirl.create(:user, :receive_notifications => "Single")

    @page.user_participations.create!(:user => user_a, :watch => true)
    @page.user_participations.create!(:user => user_b, :watch => true)
    @page.user_participations.create!(:user => user_c, :watch => true)

    PageHistory.delete_all

    @page.participation_for_user(user_a).update_attribute(:star, true)
    @page.participation_for_user(user_b).update_attribute(:star, true)
    @page.participation_for_user(user_c).update_attribute(:star, true)

    assert_equal 1, PageHistory.pending_digest_notifications_by_page.size
    assert_equal 3, PageHistory.pending_digest_notifications_by_page[@page.id].size

    last_state = Conf.paranoid_emails
    Conf.paranoid_emails = true
    PageHistory.send_digest_pending_notifications
    assert_equal 2, ActionMailer::Base.deliveries.count
    assert_equal 0, PageHistory.pending_digest_notifications_by_page.size

    Conf.paranoid_emails = last_state
    PageHistory.send_digest_pending_notifications
    assert_equal 2, ActionMailer::Base.deliveries.count
    assert_equal 0, PageHistory.pending_digest_notifications_by_page.size
  end

  def test_pending_digest_notifications_by_page
    assert_equal 1, PageHistory.pending_digest_notifications_by_page.size
  end

  def test_recipients_for_single_notifications
    user   = FactoryGirl.create(:user, :login => "user", :receive_notifications => nil)
    user_a = FactoryGirl.create(:user, :login => "user_a", :receive_notifications => "Digest")
    user_b = FactoryGirl.create(:user, :login => "user_b", :receive_notifications => "Single")
    user_c = FactoryGirl.create(:user, :login => "user_c", :receive_notifications => "Single")

    FactoryGirl.build(:user_participation, :page => @page, :user => user_a, :watch => true).save!
    FactoryGirl.build(:user_participation, :page => @page, :user => user_b, :watch => true).save!
    FactoryGirl.build(:user_participation, :page => @page, :user => user_c, :watch => true).save!

    assert_equal 2, PageHistory.recipients_for_single_notification(PageHistory.last).count

    PageHistory.last.update_attribute(:user, user_c)
    assert_equal 1, PageHistory.recipients_for_single_notification(PageHistory.last).count

    # this should not receive notifications because he has it disabled
    assert !PageHistory.recipients_for_single_notification(PageHistory.last).include?(user)

    # this should not receive notifications because he has Digest enabled
    assert !PageHistory.recipients_for_single_notification(PageHistory.last).include?(user_a)

    # this should receibe notifications because he has it enabled
    assert PageHistory.recipients_for_single_notification(PageHistory.last).include?(user_b)

    # this should not receive_notifications because he was the performer
    assert !PageHistory.recipients_for_single_notification(PageHistory.last).include?(user_c)
  end

  def test_send_pending_notifications
    user_a = FactoryGirl.create(:user, :receive_notifications => "Single")
    User.current = user_a
    FactoryGirl.build(:user_participation, :page => @page, :user => user_a, :watch => true).save!

    last_state = Conf.paranoid_emails
    Conf.paranoid_emails = false
    PageHistory.send_single_pending_notifications
    assert_equal 2, ActionMailer::Base.deliveries.count
    assert_equal 0, PageHistory.pending_notifications.size

    Conf.paranoid_emails = last_state
    PageHistory.send_single_pending_notifications
    assert_equal 2, ActionMailer::Base.deliveries.count
    assert_equal 0, PageHistory.pending_notifications.size
  end

  def test_pending_notifications
    assert_equal 2, PageHistory.pending_notifications.size
  end

  private

  def assert_change_updated_at(page, page_history)
    page.reload
    page_history.reload
    assert_equal page.updated_at, page_history.created_at
  end

  def assert_not_change_updated_at(page)
    last_updated_at = page.updated_at.to_i
    page.reload
    assert (page.updated_at.to_i - last_updated_at).abs < 2
  end
end
