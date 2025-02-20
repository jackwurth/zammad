# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Transaction::Notification
  include ChecksHumanChanges

=begin
  {
    object: 'Ticket',
    type: 'update',
    object_id: 123,
    interface_handle: 'application_server', # application_server|websocket|scheduler
    changes: {
      'attribute1' => [before, now],
      'attribute2' => [before, now],
    },
    created_at: Time.zone.now,
    user_id: 123,
  },
=end

  def initialize(item, params = {})
    @item = item
    @params = params
  end

  def perform

    # return if we run import mode
    return if Setting.get('import_mode')
    return if @item[:object] != 'Ticket'
    return if @params[:disable_notification]

    ticket = Ticket.find_by(id: @item[:object_id])
    return if !ticket

    if @item[:article_id]
      article = Ticket::Article.find(@item[:article_id])

      # ignore notifications
      sender = Ticket::Article::Sender.lookup(id: article.sender_id)
      if sender&.name == 'System'
        return if @item[:changes].blank? && article.preferences[:notification] != true

        if article.preferences[:notification] != true
          article = nil
        end
      end
    end

    # find recipients
    recipients_and_channels = []
    recipients_reason = {}

    # loop through all group users
    possible_recipients = possible_recipients_of_group(ticket.group_id)

    # loop through all mention users
    mention_users = Mention.where(mentionable_type: @item[:object], mentionable_id: @item[:object_id]).map(&:user)
    if mention_users.present?

      # only notify if read permission on group are given
      mention_users.each do |mention_user|
        next if !mention_user.group_access?(ticket.group_id, 'read')

        possible_recipients.push mention_user
        recipients_reason[mention_user.id] = __('You are receiving this because you were mentioned in this ticket.')
      end
    end

    # apply owner
    if ticket.owner_id != 1
      possible_recipients.push ticket.owner
      recipients_reason[ticket.owner_id] = __('You are receiving this because you are the owner of this ticket.')
    end

    # apply out of office agents
    possible_recipients_additions = Set.new
    possible_recipients.each do |user|
      ooo_replacements(
        user:         user,
        replacements: possible_recipients_additions,
        reasons:      recipients_reason,
        ticket:       ticket,
      )
    end

    if possible_recipients_additions.present?
      # join unique entries
      possible_recipients |= possible_recipients_additions.to_a
    end

    already_checked_recipient_ids = {}
    possible_recipients.each do |user|
      result = NotificationFactory::Mailer.notification_settings(user, ticket, @item[:type])
      next if !result
      next if already_checked_recipient_ids[user.id]

      already_checked_recipient_ids[user.id] = true
      recipients_and_channels.push result
      next if recipients_reason[user.id]

      recipients_reason[user.id] = __('You are receiving this because you are a member of the group of this ticket.')
    end

    # send notifications
    recipients_and_channels.each do |item|
      user = item[:user]
      channels = item[:channels]

      # ignore user who changed it by him self via web
      if @params[:interface_handle] == 'application_server'
        next if article&.updated_by_id == user.id
        next if !article && @item[:user_id] == user.id
      end

      # ignore inactive users
      next if !user.active?

      # ignore if no changes has been done
      changes = human_changes(@item[:changes], ticket, user)
      next if @item[:type] == 'update' && !article && changes.blank?

      # check if today already notified
      if @item[:type] == 'reminder_reached' || @item[:type] == 'escalation' || @item[:type] == 'escalation_warning'
        identifier = user.email
        if !identifier || identifier == ''
          identifier = user.login
        end

        already_notified_cutoff = Time.use_zone(Setting.get('timezone_default_sanitized')) { Time.current.beginning_of_day }

        already_notified = History.where(
          history_type_id:   History.type_lookup('notification').id,
          history_object_id: History.object_lookup('Ticket').id,
          o_id:              ticket.id
        ).where('created_at > ?', already_notified_cutoff).exists?(['value_to LIKE ?', "%#{SqlHelper.quote_like(identifier)}(#{SqlHelper.quote_like(@item[:type])}:%"])

        next if already_notified
      end

      # create online notification
      used_channels = []
      if channels['online']
        used_channels.push 'online'

        created_by_id = @item[:user_id] || 1

        # delete old notifications
        if @item[:type] == 'reminder_reached'
          seen = false
          created_by_id = 1
          OnlineNotification.remove_by_type('Ticket', ticket.id, @item[:type], user)

        elsif @item[:type] == 'escalation' || @item[:type] == 'escalation_warning'
          seen = false
          created_by_id = 1
          OnlineNotification.remove_by_type('Ticket', ticket.id, 'escalation', user)
          OnlineNotification.remove_by_type('Ticket', ticket.id, 'escalation_warning', user)

        # on updates without state changes create unseen messages
        elsif @item[:type] != 'create' && (@item[:changes].blank? || @item[:changes]['state_id'].blank?)
          seen = false
        else
          seen = OnlineNotification.seen_state?(ticket, user.id)
        end

        OnlineNotification.add(
          type:          @item[:type],
          object:        'Ticket',
          o_id:          ticket.id,
          seen:          seen,
          created_by_id: created_by_id,
          user_id:       user.id,
        )
        Rails.logger.debug { "sent ticket online notifiaction to agent (#{@item[:type]}/#{ticket.id}/#{user.email})" }
      end

      # ignore email channel notification and empty emails
      if !channels['email'] || user.email.blank?
        add_recipient_list(ticket, user, used_channels, @item[:type])
        next
      end

      used_channels.push 'email'
      add_recipient_list(ticket, user, used_channels, @item[:type])

      # get user based notification template
      # if create, send create message / block update messages
      template = case @item[:type]
                 when 'create'
                   'ticket_create'
                 when 'update'
                   'ticket_update'
                 when 'reminder_reached'
                   'ticket_reminder_reached'
                 when 'escalation'
                   'ticket_escalation'
                 when 'escalation_warning'
                   'ticket_escalation_warning'
                 when 'update.merged_into'
                   'ticket_update_merged_into'
                 when 'update.received_merge'
                   'ticket_update_received_merge'
                 else
                   raise "unknown type for notification #{@item[:type]}"
                 end

      current_user = User.lookup(id: @item[:user_id])
      if !current_user
        current_user = User.lookup(id: 1)
      end

      attachments = []
      if article
        attachments = article.attachments_inline
      end
      NotificationFactory::Mailer.notification(
        template:    template,
        user:        user,
        objects:     {
          ticket:       ticket,
          article:      article,
          recipient:    user,
          current_user: current_user,
          changes:      changes,
          reason:       recipients_reason[user.id],
        },
        message_id:  "<notification.#{DateTime.current.to_s(:number)}.#{ticket.id}.#{user.id}.#{SecureRandom.uuid}@#{Setting.get('fqdn')}>",
        references:  ticket.get_references,
        main_object: ticket,
        attachments: attachments,
      )
      Rails.logger.debug { "sent ticket email notifiaction to agent (#{@item[:type]}/#{ticket.id}/#{user.email})" }
    end

  end

  def add_recipient_list(ticket, user, channels, type)
    return if channels.blank?

    identifier = user.email
    if !identifier || identifier == ''
      identifier = user.login
    end
    recipient_list = "#{identifier}(#{type}:#{channels.join(',')})"
    History.add(
      o_id:           ticket.id,
      history_type:   'notification',
      history_object: 'Ticket',
      value_to:       recipient_list,
      created_by_id:  @item[:user_id] || 1
    )
  end

  private

  def ooo_replacements(user:, replacements:, ticket:, reasons:)
    replacement = user.out_of_office_agent

    return if !replacement

    return if !TicketPolicy.new(replacement, ticket).agent_read_access?

    return if !replacements.add?(replacement)

    reasons[replacement.id] = __('You are receiving this because you are out-of-office replacement for a participant of this ticket.')
  end

  def possible_recipients_of_group(group_id)
    Rails.cache.fetch("User/notification/possible_recipients_of_group/#{group_id}", expires_in: 20.seconds) do
      User.group_access(group_id, 'full').sort_by(&:login)
    end
  end
end
