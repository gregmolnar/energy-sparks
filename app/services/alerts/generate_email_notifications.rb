module Alerts
  class GenerateEmailNotifications
    def perform
      Contact.all.each do |contact|
        events = contact.alert_subscription_events.where(status: :pending, communication_type: :email)
        if events.any?
          email = Email.create(contact: contact)
          alerts = events.map(&:alert)
          events.update_all(email_id: email.id)

          AlertMailer.with(email_address: contact.email_address, alerts: alerts, school: contact.school).alert_email.deliver_now
          events.update_all(status: :sent, email_id: email.id)
          email.update(sent_at: Time.now.utc)
        end
      end
    end
  end
end
