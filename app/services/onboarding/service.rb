module Onboarding
  class Service
    include Wisper::Publisher
    include NewsletterSubscriber

    def complete_onboarding(school_onboarding, users)
      school_onboarding.events.create(event: :onboarding_complete)
      school_onboarding.school.update!(visible: true) if set_visible_on_completion?
      send_confirmation_instructions(users)
      create_additional_contacts(school_onboarding, users)
      subscribe_users_to_newsletter(school_onboarding, school_onboarding.school.users)
      enrol_in_default_programme(school_onboarding.school)
      broadcast(:onboarding_completed, school_onboarding)
    end

    def should_complete_onboarding?(school)
      school.school_onboarding && school.school_onboarding.incomplete?
    end

    def record_event(onboarding, *events)
      result = yield if block_given?
      if onboarding
        events.each do |event|
          onboarding.events.create(event: event)
        end
      end
      result
    end

    private

    def set_visible_on_completion?
      EnergySparks::FeatureFlags.active?(:data_enabled_onboarding)
    end

    def enrol_in_default_programme(school)
      Programmes::Enroller.new.enrol(school)
    end

    def send_confirmation_instructions(users)
      users.each do |user|
        user.send_confirmation_instructions unless user.confirmed?
      end
    end

    def create_additional_contacts(school_onboarding, users)
      users.each do |user|
        unless user.contacts.where(school: school_onboarding.school).any?
          school_onboarding.events.create(event: :alert_contact_created)
          school_onboarding.school.contacts.create!(
            user: user,
            name: user.display_name,
            email_address: user.email,
            description: 'School Energy Sparks contact'
          )
        end
      end
    end

    def subscribe_users_to_newsletter(school_onboarding, users)
      users.each do |user|
        subscribe_newsletter(school_onboarding.school, user) if user_subscribed_to_newsletter?(school_onboarding, user)
      end
    end
  end
end
