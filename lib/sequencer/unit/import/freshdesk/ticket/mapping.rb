# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Freshdesk::Ticket::Mapping < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped

  uses :resource, :id_map

  # Since the imports rely on a fresh Zammad installation, we
  #   can require the default priority and state names to be present.
  def priority_map
    @priority_map ||= {
      1 => ::Ticket::Priority.find_by(name: '1 low')&.id, # low
      2 => ::Ticket::Priority.find_by(name: '2 normal')&.id, # medium
      3 => ::Ticket::Priority.find_by(name: '3 high')&.id, # high
      4 => ::Ticket::Priority.find_by(name: '3 high')&.id, # urgent
    }.freeze
  end

  def state_map
    @state_map ||= {
      2 => ::Ticket::State.find_by(name: 'open')&.id, # open
      3 => ::Ticket::State.find_by(name: 'pending reminder')&.id, # pending
      4 => ::Ticket::State.find_by(name: 'closed')&.id, # resolved
      5 => ::Ticket::State.find_by(name: 'closed')&.id, # closed
    }.freeze
  end

  def process
    provide_mapped do
      {
        title:       resource['subject'],
        number:      resource['id'],
        group_id:    group_id,
        priority_id: priority_id,
        state_id:    state_id,
        owner_id:    owner_id,
        customer_id: customer_id,
        type:        resource['type'],
        created_at:  resource['created_at'],
        updated_at:  resource['updated_at'],
      }
    end
  end

  private

  def group_id
    id_map.dig('Group', resource['group_id']) || ::Group.find_by(name: 'Support')&.id || 1
  end

  def customer_id
    id_map['User'][resource['requester_id']]
  end

  def owner_id
    id_map['User'][resource['responder_id']]
  end

  def state_id
    state_map.fetch(resource['status'], default_state_id)
  end

  def priority_id
    priority_map.fetch(resource['priority'], default_priority_id)
  end

  def default_state_id
    @default_state_id ||= ::Ticket::State.find_by(name: 'open')&.id
  end

  def default_priority_id
    @default_priority_id ||= ::Ticket::Priority.find_by(name: '2 normal')&.id
  end
end
