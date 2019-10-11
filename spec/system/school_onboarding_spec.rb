require 'rails_helper'

RSpec.describe "school onboarding", :schools, type: :system do

  let(:school_name)               { 'Oldfield Park Infants'}

  # This calendar is there to allow for the calendar area selection
  let!(:template_calendar)        { create(:regional_calendar, :with_terms, title: 'BANES calendar') }
  let(:solar_pv_area)             { create(:solar_pv_tuos_area, title: 'BANES solar') }
  let(:dark_sky_weather_area)     { create(:dark_sky_area, title: 'BANES dark sky weather') }
  let!(:school_group) do
    create(
      :school_group,
      name: 'BANES',
      default_template_calendar: template_calendar,
      default_solar_pv_tuos_area: solar_pv_area,
      default_dark_sky_area: dark_sky_weather_area
    )
  end

  let(:admin) { create(:admin)}

  let!(:headteacher_role) { create(:staff_role, :management, title: 'Headteacher')}

  context 'as an admin' do


    before(:each) do
      sign_in(admin)
      visit root_path
    end

    it 'records basic details and sends an email to the school' do
      within '.navbar' do
        click_on 'Automatic School Setup'
      end
      click_on 'New Automatic School Setup'

      fill_in 'School name', with: school_name
      fill_in 'Contact email', with: 'oldfield@test.com'

      select 'BANES', from: 'Group'
      click_on 'Next'

      expect(page).to have_select('Template calendar', selected: 'BANES calendar')
      expect(page).to have_select('Solar PV from The University of Sheffield Data Feed Area', selected: 'BANES solar')
      expect(page).to have_select('Dark Sky Data Feed Area', selected: 'BANES dark sky weather')

      click_on 'Next'

      expect(page).to have_content(school_name)
      expect(page).to have_content("oldfield@test.com")

      click_on "Send setup email"

      onboarding = SchoolOnboarding.first

      email = ActionMailer::Base.deliveries.last
      expect(email.subject).to include('Set up your school on Energy Sparks')
      expect(email.html_part.body.to_s).to include(onboarding_path(onboarding))
    end

    it 'sends reminder emails when requested' do
      onboarding = create :school_onboarding
      within '.navbar' do
        click_on 'Automatic School Setup'
      end
      click_on 'Send reminder'

      email = ActionMailer::Base.deliveries.last
      expect(email.subject).to include("Don't forget to set up your school on Energy Sparks")
      expect(email.html_part.body.to_s).to include(onboarding_path(onboarding))
    end

    it 'I can amend the email address if the user has not responded' do
      onboarding = create :school_onboarding, :with_events, event_names: [:email_sent]

      within '.navbar' do
        click_on 'Automatic School Setup'
      end

      expect(onboarding.has_only_sent_email_or_reminder?).to be true

      click_on 'Change'
      expect(page).to have_content('Change email address')

      fill_in(:school_onboarding_contact_email, with: '')
      click_on 'Save'

      expect(page).to have_content('Change email address')

      new_email_address = 'oof@youareawful.com'
      fill_in(:school_onboarding_contact_email, with: new_email_address)

      click_on 'Save'

      expect(page).to have_content(new_email_address)

      email = ActionMailer::Base.deliveries.last
      expect(email.to).to include(new_email_address)

      onboarding.reload

      expect(onboarding.has_only_sent_email_or_reminder?).to be true

      expect(onboarding.contact_email).to eq new_email_address
    end
  end

  context 'as school user signing up' do

    let!(:ks1) { KeyStage.create(name: 'KS1') }

    let!(:onboarding) do
      create(
        :school_onboarding, :with_events,
        event_names: [:email_sent],
        school_name: school_name,
        template_calendar: template_calendar,
        created_by: admin
      )
    end

    before(:each) do
      visit onboarding_path(onboarding)
    end

    it 'walks the user through the steps required' do
      expect(page).to have_content('Welcome to Energy Sparks')
      click_on 'Next'

      click_on 'I give permission'
      expect(page).to have_content('Please confirm')

      check 'I confirm agreement with the Energy Sparks privacy policy'
      click_on 'I give permission'

      onboarding.reload
      expect(onboarding).to have_event(:permission_given)
      expect(onboarding).to have_event(:privacy_policy_agreed)

      expect(page).to have_field('Email', with: onboarding.contact_email)
      fill_in 'Your name', with: 'A Teacher'
      select 'Headteacher', from: 'Role'
      fill_in 'Password', with: 'testtest1', match: :prefer_exact
      fill_in 'Password confirmation', with: 'testtest1'
      click_on 'Create my account'

      onboarding.reload
      expect(onboarding.created_user.name).to eq('A Teacher')
      expect(onboarding.created_user.role).to eq('school_onboarding')

      fill_in 'Unique Reference Number', with: '4444244'
      fill_in 'Number of pupils', with: 300
      fill_in 'Floor area in square metres', with: 400
      fill_in 'Address', with: '1 Station Road'
      fill_in 'Postcode', with: 'A1 2BC'
      fill_in 'Website', with: 'http://oldfield.sch.uk'

      check 'Our school has solar PV panels'
      uncheck 'Our school has its own swimming pool'
      check 'Our school serves school dinners on site'
      check 'Dinners are cooked on site'
      check 'The kitchen cooks dinners for other schools'
      fill_in 'How many schools does your school cook dinners for?', with: '5'

      choose 'Primary'
      check 'KS1'

      click_on 'Update school details'

      click_on "I've finished"
      expect(onboarding).to have_event(:onboarding_complete)
      onboarding.reload

      expect(onboarding.school.has_solar_panels?).to eq(true)
      expect(onboarding.school.has_swimming_pool?).to eq(false)
      expect(onboarding.school.cooks_dinners_for_other_schools_count).to eq(5)

      expect(page).to have_content("We'll have a look at school details you've sent us and let you know when your school goes live.")

      email = ActionMailer::Base.deliveries.last
      expect(email.subject).to include('Oldfield Park Infants has completed the onboarding process')
      expect(email.to).to include(admin.email)
    end

    it 'lets the user edit inset days, meters and opening times but does not require them' do
      create :calendar_event_type, title: 'Teacher training', inset_day: true
      academic_year = create :academic_year, start_date: Date.new(2018, 9,1), end_date: Date.new(2019, 8, 31)
      user = create(:onboarding_user)
      onboarding.update!(created_user: user)
      school = build(:school)
      SchoolCreator.new(school).onboard_school!(onboarding)

      sign_in(user)
      visit new_onboarding_completion_path(onboarding)

      # Meters
      expect(page).to have_content('Meters: 0')
      click_on 'Add a meter'
      fill_in 'Meter Point Number', with: '123543'
      fill_in 'Meter Name', with: 'Gas'
      choose 'Gas'
      click_on 'Create Meter'
      expect(page).to have_content('Meters: 1')

      # Opening times
      expect(page).to have_content('Monday 08:50 - 15:20')
      click_on 'Set school times'
      fill_in 'monday-opening_time', with: '900'
      click_on 'Update school times'
      expect(page).to have_content('Monday 09:00 - 15:20')

      # Inset days
      expect(page).to have_content('Inset days: 0')
      click_on 'Add an inset day'
      fill_in 'Description', with: 'Teacher training'
      select 'Teacher training', from: 'Type'
      # Grr, actual input hidden for JS datepicker
      fill_in 'Date', with: '2019-01-09'
      click_on 'Add inset day'
      expect(page).to have_content('Inset days: 1')
    end

    it 'adds the onboarding user as an alert contact and allows management' do
      user = create(:onboarding_user)
      onboarding.update!(created_user: user)
      school = build(:school)
      SchoolCreator.new(school).onboard_school!(onboarding)

      sign_in(user)

      visit new_onboarding_completion_path(onboarding)

      click_on 'Edit your account'

      fill_in 'Your name', with: 'Better name'
      click_on 'Update my account'
      user.reload
      expect(user.name).to eq('Better name')

      click_on 'Edit school details'
      fill_in 'School name', with: 'Correct school'
      click_on 'Update school details'
      school.reload
      expect(school.name).to eq('Correct school')

    end

    it 'lets the user edit and add contacts' do
      user = create(:onboarding_user)
      onboarding.update!(created_user: user)
      school = build(:school)
      SchoolCreator.new(school).onboard_school!(onboarding)

      sign_in(user)

      visit new_onboarding_completion_path(onboarding)

      within '#alert-contacts' do
        expect(page).to have_content(user.name)
        click_on 'Edit'
      end

      fill_in 'Mobile phone number', with: '07123 4567890'
      click_on 'Save'
      expect(school.contacts.first.mobile_phone_number).to eq('07123 4567890')

      within '#alert-contacts' do
        click_on 'Delete'
      end

      expect(school.contacts.size).to eq(0)

      click_on 'Add an alert contact'

      fill_in 'Name', with: 'Joe Bloggs'
      fill_in 'Email', with: 'test@example.com'
      click_on 'Save'

      expect(school.contacts.size).to eq(1)

    end

  end
end

