namespace :targets do
  desc 'Send email to set first target'
  task send_first_target: [:environment] do
    puts "#{Time.zone.now} Sending first target invite emails"
    if ENV['SEND_AUTOMATED_EMAILS']
      Targets::TargetMailerService.new.invite_schools_to_set_first_target
    else
      puts "#{Time.zone.now} Automated emails disabled, not sending invites"
    end
    puts "#{Time.zone.now} Finished sending first target invite emails"
  end
end
