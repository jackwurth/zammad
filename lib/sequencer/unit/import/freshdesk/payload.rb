# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Freshdesk::Payload < Sequencer::Unit::Import::Common::ImportJob::Payload::ToAttribute

  provides :tickets_updated_since, :skip_time_entries
end
