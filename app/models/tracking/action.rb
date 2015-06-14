module Tracking::Action

  EVENT_CREATES_ACTIVITIES = {
    create_group: ['GroupCreatedActivity', 'UserCreatedGroupActivity'],
    create_membership: ['GroupGainedUserActivity', 'UserJoinedGroupActivity'],
    destroy_membership: ['GroupLostUserActivity', 'UserLeftGroupActivity'],
    request_to_destroy_group: ['UserProposedToDestroyGroupActivity'],
    create_friendship: ['FriendActivity']
  }

  def self.track(event, options = {})
    options[:key] ||= rand(Time.now.to_i)
    EVENT_CREATES_ACTIVITIES[event].each do |class_name|
      klass = class_name.constantize
      klass.create! filter_options_for_class(klass, options)
    end
  end

  protected

  def self.filter_options_for_class(klass, options)
    options.select do |k,v|
      klass.attribute_method?("#{k}=") ||
        klass.method_defined?("#{k}=")
    end
  end
end