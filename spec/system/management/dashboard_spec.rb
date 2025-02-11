require 'rails_helper'

describe 'Management dashboard' do

  let(:school_name)         { 'Theresa Green Infants'}
  let!(:school_group)       { create(:school_group) }
  let!(:regional_calendar)  { create(:regional_calendar) }
  let!(:calendar)           { create(:school_calendar, based_on: regional_calendar) }
  let!(:school)             { create(:school, :with_feed_areas, calendar: calendar, name: school_name, school_group: school_group) }
  let!(:intervention)       { create(:observation, school: school) }

  let!(:school_admin)       { create(:school_admin, school: school)}
  let(:staff)               { create(:staff, school: school, staff_role: create(:staff_role, :management)) }

  let(:management_table) {
    [
      ["", "Annual Use (kWh)", "Annual CO2 (kg)", "Annual Cost", "Change from last year", "Change in last 4 school weeks", "Potential savings"],
      ["Electricity", "730,000", "140,000", "£110,000", "+12%", "-8.5%", "£83,000"],
      ["Gas", "not enough data", "not enough data", "not enough data", "not enough data", "-50%", "not enough data"]
    ]
  }

  let(:management_data) {
    Tables::SummaryTableData.new({ electricity: { year: { :percent_change => 0.11050 }, workweek: { :percent_change => -0.0923132131 } } })
  }

  before(:each) do
    allow_any_instance_of(Schools::ManagementTableService).to receive(:management_table).and_return(management_table)
    allow_any_instance_of(Schools::ManagementTableService).to receive(:management_data).and_return(management_data)
  end

  describe 'when not logged in' do
    it 'prompts for login' do
      visit management_school_path(school)
      expect(page).to have_content("Sign in to Energy Sparks")
    end
  end

  context 'when school is data-enabled' do

    context 'and logged in as pupil' do
      let(:pupil) { create(:pupil, school: school)}

      before(:each) do
        sign_in(pupil)
        visit root_path
      end

      it 'allows access to dashboard' do
        expect(page).to have_content("#{school.name}")
        expect(page).to have_link("Adult dashboard", href: management_school_path(school))
      end

      it 'has link to adult dashboard' do
        click_on 'Adult dashboard'
        expect(page).to have_content("#{school.name}")
        expect(page).to have_link("Compare schools")
      end

      it 'shows temperature observations' do
        #this is from the default observation created above
        expect(page).to have_content("Recorded temperatures")
      end

      it 'does not display energy saving target prompt' do
        allow(EnergySparks::FeatureFlags).to receive(:active?).and_return(true)
        allow_any_instance_of(::Targets::SchoolTargetService).to receive(:enough_data?).and_return(true)
        visit management_school_path(school)
        expect(page).to_not have_content("Set targets to reduce your school's energy consumption")
        expect(page).to_not have_link('Set energy saving target')
      end

    end

    context 'and logged in as a school admin' do
      before(:each) do
        sign_in(school_admin)
        visit management_school_path(school)
      end

      it 'allows access to dashboard' do
        expect(page).to have_content(school_name)
      end

    end

    context 'and logged in as staff' do
      before(:each) do
        sign_in(staff)
      end

      it 'allows access to dashboard' do
        visit management_school_path(school)
        expect(page).to have_content("#{school.name}")
        expect(page).to have_content("Adult Dashboard")
      end

      it 'shows the expected prompts' do
        visit management_school_path(school)
        expect(page).to have_link("View your programmes")
        expect(page).to have_link("Record a pupil activity")
        expect(page).to have_link("Record an action")
      end

      it 'shows data-enabled features' do
        ClimateControl.modify FEATURE_FLAG_USE_MANAGEMENT_DATA: 'false' do
          visit management_school_path(school)
          expect(page).to have_content("Your annual usage")
        end
        ClimateControl.modify FEATURE_FLAG_USE_MANAGEMENT_DATA: 'true' do
          visit management_school_path(school)
          expect(page).to have_content("Summary of recent energy usage")
        end
      end

      it 'shows data-enabled links' do
        visit management_school_path(school)
        expect(page).to have_link("Compare schools")
        expect(page).to have_link("Explore your data")
        expect(page).to have_link("Review your energy analysis")
        expect(page).to have_link("Print view")
      end

      it 'shows temperature observations' do
        visit management_school_path(school)
        #this is from the default observation created above
        expect(page).to have_content("Recorded temperatures")
      end

      context 'with management priorities' do

        let!(:gas_fuel_alert_type) { create(:alert_type, fuel_type: :gas, frequency: :weekly) }
        let!(:alert_type_rating) do
          create(
            :alert_type_rating,
            alert_type: gas_fuel_alert_type,
            rating_from: 0,
            rating_to: 10,
            management_priorities_active: true,
          )
        end
        let!(:alert_type_rating_content_version) do
          create(
            :alert_type_rating_content_version,
            alert_type_rating: alert_type_rating,
            management_priorities_title: 'Spending too much money on heating',
          )
        end
        let(:alert_summary){ 'Summary of the alert' }
        let!(:alert) do
          create(:alert, :with_run,
            alert_type: gas_fuel_alert_type,
            run_on: Date.today, school: school,
            rating: 9.0,
            template_data: {
              average_capital_cost: '£2,000'
            }
          )
        end

        before do
          Alerts::GenerateContent.new(school).perform
        end

        it 'displays the priorities in a table' do
          visit management_school_path(school)
          expect(page).to have_content('Spending too much money on heating')
          expect(page).to have_content('£2,000')
        end

        it 'displays energy saving target prompt' do
          allow(EnergySparks::FeatureFlags).to receive(:active?).and_return(true)
          allow_any_instance_of(::Targets::SchoolTargetService).to receive(:enough_data?).and_return(true)

          visit management_school_path(school)
          expect(page).to have_content("Set targets to reduce your school's energy consumption")
          expect(page).to have_link('Set energy saving target')

          school.school_targets << create(:school_target)
          visit management_school_path(school)
          expect(page).not_to have_content("Set targets to reduce your school's energy consumption")
        end

        it 'doesnt displays energy saving target prompt if not enough data' do
          allow(EnergySparks::FeatureFlags).to receive(:active?).and_return(true)
          allow_any_instance_of(::Targets::SchoolTargetService).to receive(:enough_data?).and_return(false)

          visit management_school_path(school)
          expect(page).to_not have_content("Set targets to reduce your school's energy consumption")
        end

        it 'doesnt display prompt if feature disabled for school' do
          allow(EnergySparks::FeatureFlags).to receive(:active?).and_return(true)
          school.update!(enable_targets_feature: false)
          visit management_school_path(school)
          expect(page).to_not have_content("Set targets to reduce your school's energy consumption")
        end

        it 'displays a report version of the page' do
          visit management_school_path(school)
          click_on 'Print view'
          expect(page).to have_content("Management information for #{school.name}")
          expect(page).to have_content('Spending too much money on heating')
          expect(page).to have_content('£2,000')
        end
      end

      context 'with school targets' do
        let(:progress_summary) { nil }
        let!(:school_target)    { create(:school_target, school: school) }

        before(:each) do
          allow_any_instance_of(Targets::ProgressService).to receive(:progress_summary).and_return(progress_summary)
          visit school_path(school)
        end

        context 'and there is no data' do
          it 'has no notice' do
            expect(page).to_not have_content("Well done, you are currently meeting your target")
            expect(page).to_not have_content("Unfortunately you are not meeting your targets")
          end
        end

        context 'that are being met' do
          let(:progress_summary)  { build(:progress_summary, school_target: school_target) }
          it 'displays a notice' do
            expect(page).to have_content("Well done, you are currently meeting your target")
          end

          it 'links to target page' do
            expect(page).to have_link("Review progress", href: school_school_targets_path(school))
          end
        end

        context 'and gas is not being met' do
          let(:progress_summary)  { build(:progress_summary_with_failed_target, school_target: school_target) }

          it 'displays a notice' do
            expect(page).to have_content("Unfortunately you are not meeting your target to reduce your gas usage")
            expect(page).to have_content("Well done, you are currently meeting your target to reduce your electricity and storage heater usage")
          end

          it 'links to target page' do
            expect(page).to have_link("Review progress", href: school_school_targets_path(school))
          end
        end

        context 'with lagging data' do
          let(:electricity_progress) { build(:fuel_progress, recent_data: false)}
          let(:progress_summary)  { build(:progress_summary, electricity: electricity_progress, school_target: school_target) }

          it 'displays a notice' do
            expect(page).to_not have_content("Unfortunately you are not meeting your target")
            expect(page).to have_content("Well done, you are currently meeting your target to reduce your gas and storage heater usage")
          end

          it 'links to target page' do
            expect(page).to have_link("Review progress", href: school_school_targets_path(school))
          end
        end

      end

      context 'with co2 analysis' do
          before(:each) do
            co2_page = double(analysis_title: 'Some CO2 page', analysis_page: 'analysis/page/co2')
            expect_any_instance_of(Management::SchoolsController).to receive(:process_analysis_templates).and_return([co2_page])
            visit management_school_path(school)
          end
          it 'shows link to co2 analysis page' do
            expect(page).to have_link("Some CO2 page")
          end
      end

      context 'with observations' do
        before(:each) do
          intervention_type = create(:intervention_type, title: 'Upgraded insulation')
          create(:observation, :intervention, school: school, intervention_type: intervention_type)
          create(:observation_with_temperature_recording_and_location, school: school)
          activity_type = create(:activity_type) # doesn't get saved if built with activity below
          create(:activity, school: school, activity_type: activity_type)
          visit management_school_path(school)
        end

        it 'displays interventions and temperature recordings in a timeline' do
          expect(page).to have_content('Recorded temperatures in')
          expect(page).to have_content('Upgraded insulation')
          expect(page).to have_content('Completed an activity')
          click_on 'View all events'
          expect(page).to have_content('Recorded temperatures in')
          expect(page).to have_content('Upgraded insulation')
          expect(page).to have_content('Completed an activity')
        end
      end

    end

  end

  context 'when school is not data-enabled' do
    before(:each) do
      school.update!(data_enabled: false)
    end

    context 'and logged in as admin' do
      let!(:admin)    { create(:admin) }
      before(:each) do
        sign_in(admin)
      end

      it 'overrides flag and shows data-enabled features' do
        ClimateControl.modify FEATURE_FLAG_USE_MANAGEMENT_DATA: 'false' do
          visit management_school_path(school)
          expect(page).to have_content("Your annual usage")
        end
        ClimateControl.modify FEATURE_FLAG_USE_MANAGEMENT_DATA: 'true' do
          visit management_school_path(school)
          expect(page).to have_content("Summary of recent energy usage")
        end
      end

      it 'overrides flag and shows data-enabled links' do
        visit management_school_path(school)
        expect(page).to have_link("Compare schools")
        expect(page).to have_link("Explore your data")
        expect(page).to have_link("Review your energy analysis")
        expect(page).to have_link("Download your data")
      end

      it 'shows link to user view' do
        visit management_school_path(school)
        expect(page).to have_link("User view")
        click_on("User view")
        expect(page).to have_link("Admin view")
        expect(page).to_not have_link("Explore your data")
        expect(page).to_not have_content("Your annual usage")
      end
    end

    context 'and logged in as staff' do
      before(:each) do
        sign_in(staff)
        visit management_school_path(school)
      end

      it 'allows access to dashboard' do
        expect(page).to have_content("#{school.name}")
        expect(page).to have_content("Adult Dashboard")
      end

      it 'shows the expected prompts' do
        expect(page).to have_link("Find training")
        expect(page).to have_link("View your programmes")
        expect(page).to have_link("Record a pupil activity")
        expect(page).to have_link("Record an action")
      end

      it 'shows temperature observations' do
        #this is from the default observation created above
        expect(page).to have_content("Recorded temperatures")
      end

      it 'does not show data-enabled features' do
        expect(page).to_not have_content("Your annual usage")
      end

      it 'shows placeholder chart' do
        expect(page).to have_css(".chart-placeholder-image")
      end

      it 'does not show data-enabled links' do
        expect(page).to_not have_link("Compare schools")
        expect(page).to_not have_link("Explore your data")
        expect(page).to_not have_link("Review your energy analysis")
        expect(page).to_not have_link("Print view")
      end

    end
  end
end
