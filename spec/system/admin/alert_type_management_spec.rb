require 'rails_helper'

RSpec.describe 'alert type management', type: :system do

  let!(:admin)  { create(:user, role: 'admin')}

  let!(:gas_fuel_alert_type) { create(:alert_type, fuel_type: :gas, frequency: :termly, title: 'Your gas usage is too high', has_variables: true) }


  describe 'managing associated activities' do

    let!(:activity_category) { create(:activity_category)}
    let!(:activity_type_1) { create(:activity_type, name: 'Turn off the lights', activity_category: activity_category)}
    let!(:activity_type_2) { create(:activity_type, name: 'Turn down the heating', activity_category: activity_category)}

    before do
      sign_in(admin)
      visit root_path
      click_on 'Alert Types'
    end

    it 'assigns activity types to alerts via a text box position' do

      click_on 'Your gas usage is too high'
      click_on 'Associated activity types'

      expect(page.find_field('Turn off the light').value).to be_blank
      expect(page.find_field('Turn down the heating').value).to be_blank

      fill_in 'Turn down the heating', with: '1'

      click_on 'Update associated activity type', match: :first

      expect(page.find_field('Turn off the light').value).to be_blank
      expect(page.find_field('Turn down the heating').value).to eq('1')

      expect(gas_fuel_alert_type.activity_types).to match_array([activity_type_2])
      expect(gas_fuel_alert_type.alert_type_activity_types.first.position).to eq(1)

    end
  end

  describe 'creating find out more copy' do

    let!(:alert) do
      create(:alert, alert_type: gas_fuel_alert_type, template_data: {gas_percentage: '10%'}, school: create(:school))
    end

    before do
      sign_in(admin)
      visit root_path
      click_on 'Manage'
      click_on 'Alert Types'
    end

    it 'allows creation and editing of alert content', js: true do

      click_on 'Your gas usage is too high'
      click_on 'Content management'

      click_on 'New content'

      fill_in 'Rating from', with: '0'
      fill_in 'Rating to', with: '10'
      fill_in 'Description', with: 'For schools with bad heating management'

      select 'red', from: 'Colour'

      fill_in 'Teacher dashboard title', with: 'Your gas usage is too high'
      fill_in 'Pupil dashboard title', with: 'You are using too much gas'
      fill_in 'Page title', with: 'You are using too much gas!'

      editor = find('trix-editor')
      editor.click.set('You are using {{gas_percentage}} too much gas! You need to do something about it.')

      click_on 'Preview'

      within '#preview .content' do
        expect(page).to have_content('You are using 10% too much gas!')
      end

      click_on 'Create content'

      expect(gas_fuel_alert_type.ratings.size).to eq(1)
      alert_type_rating = gas_fuel_alert_type.ratings.first
      expect(alert_type_rating.content_versions.size).to eq(1)
      first_content = alert_type_rating.current_content
      expect(first_content.page_title).to eq('You are using too much gas!')

      click_on 'Edit'

      fill_in 'Page title', with: 'Stop using so much gas!'
      click_on 'Update content'

      expect(alert_type_rating.content_versions.size).to eq(2)
      second_content = alert_type_rating.current_content
      expect(second_content.page_title).to eq('Stop using so much gas!')


    end
  end

end
