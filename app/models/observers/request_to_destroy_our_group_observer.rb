class RequestToDestroyOurGroupObserver < ActiveRecord::Observer
  def after_create(request)
    key = rand(Time.now.to_i)
    request.group.users.each do |user|
      UserProposedToDestroyGroupActivity.create!(:user => request.created_by, :group => request.group, :key => key)

      # Mailer is disabled for now
      # Mailer.deliver_request_to_destroy_our_group(request, user)
    end
  end
end
