#
# recipient: group who may be added to network
# requestable: the network
# created_by: person who sent the invite
#
class RequestToJoinOurNetwork < Request

  validates_format_of :requestable_type, :with => /Group/
  validates_format_of :recipient_type, :with => /Group/

  validate :requestable_is_network
  validate :no_membership_yet
  validate :no_request_yet
  validate :group_is_not_network
  validate :group_is_not_network_committee

  def network() requestable end
  def group() recipient end

  def may_create?(user)
    user.may?(:admin,network)
  end

  def may_approve?(user)
    user.may?(:admin,group)
  end

  def may_destroy?(user)
    user.may?(:admin, network)
  end

  def may_view?(user)
    may_create?(user) or may_approve?(user)
  end

  def after_approval
    network.add_group!(group)
  end

  def description
    [:request_to_join_our_network_description, {:group => group_span(group), :network => group_span(network)}]
  end

  def short_description
    [:request_to_join_our_network_short, {:group => group_span(group), :network => group_span(network)}]
  end

  def icon_entity
    self.recipient
  end

  protected

  def requestable_is_network
    unless requestable.type =~ /Network/
      errors.add_to_base('requestable must be a network')
    end
  end

  def no_membership_yet
    if Federating.find_by_group_id_and_network_id(group.id, network.id)
      errors.add_to_base(I18n.t(:membership_exists_error, :member => group.name))
    end
  end

  def no_request_yet
    if RequestToJoinOurNetwork.having_state(state).find_by_recipient_id_and_requestable_id_and_state(recipient_id, requestable_id, state)
      errors.add_to_base(I18n.t(:request_exists_error, :recipient => recipient.name))
    end
  end

  def group_is_not_network
    if group.network?
      errors.add_to_base(I18n.t(:networks_may_not_join_networks))
    end
  end

  def group_is_not_network_committee
    if group.committee? && group.parent.network?
      errors.add_to_base(I18n.t(:network_committees_may_not_join_networks))
    end
  end
end

