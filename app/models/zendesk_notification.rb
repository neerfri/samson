require 'zendesk_api'
require 'net/http/persistent'

class ZendeskNotification
  cattr_accessor(:zendesk_url) { ENV['ZENDESK_URL'] }
  cattr_accessor(:access_token) { ENV['ZENDESK_TOKEN'] }

  def initialize(stage, deploy)
    @stage, @deploy = stage, deploy
  end

  def deliver
    zendesk_tickets = @deploy.changeset.zendesk_tickets

    if zendesk_tickets.any?
      zendesk_tickets.each do |ticket_id|
        attributes = {
          :id => ticket_id,
          :status => "open",
          :comment => { :value => content(ticket_id), :public => false }
        }

        if zendesk_client.tickets.update(attributes)
          Rails.logger.info "Updated Zendesk ticket: #{ticket_id} with a comment"
        else
          Rails.logger.warn "Failed to modify ticket with GitHub update: #{ticket.errors}"
        end
      end
    else
      Rails.logger.info "There are no tickets to update in this deploy. Reference: #{@deploy.short_reference}"
    end
  end

  private

  def zendesk_client
    @zendesk_client ||= ZendeskAPI::Client.new do |config|
      config.url = "#{zendesk_url}/api/v2"
      config.access_token = access_token
      config.adapter = :net_http_persistent
    end
  end

  def content(ticket_id)
    @content = ZendeskNotificationRenderer.render(@deploy, ticket_id)
  end
end
