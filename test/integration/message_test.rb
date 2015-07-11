require 'javascript_integration_test'

class MessageTest < JavascriptIntegrationTest
  include Integration::Comments


  def test_send_message
    msg = "Here is my Message"
    login users(:blue)
    send_message msg, to: 'red'
    assert_content msg
  end

  def test_send_message_from_discussion
    msg = "Here is my Message"
    login users(:blue)
    send_message msg, to: 'red'
    assert_content msg
    fill_in 'post_body', with: "other message"
    click_on 'Post Message'
    assert_selector '.private_post', text: "other message"
    save_screenshot '/tmp/posted.png'
  end

  def test_edit_message
    msg = "Here is my Message"
    new_msg = "Now here is something new!"
    login users(:blue)
    send_message msg, to: 'red'
    edit_comment msg, new_msg
    assert_content new_msg
    assert_no_content msg
  end

  def test_delete_message
    text = "Here is my Message"
    blue = users(:blue)
    red = users(:red)
    login blue
    new_msg = blue.send_message_to!(red, text, nil)
    msg_id = "#private_post_#{new_msg.id}"

    visit "/me/messages/#{red.login}/posts"

    assert_selector msg_id

    hover_and_edit(text) do
      click_on 'Delete'
    end

    assert_no_selector msg_id
  end

  private

  def send_message(msg, options = {})
    click_on 'Messages'
    fill_in 'Recipient', with: options[:to]
    fill_in 'Message', with: msg
    click_on 'Send'
  end

end

