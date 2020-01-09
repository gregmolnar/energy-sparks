require 'rails_helper'

describe ImportNotifier do

  let(:sheffield_config) { create(:amr_data_feed_config, description: 'Sheffield', import_warning_days: 5) }
  let(:bath_config) { create(:amr_data_feed_config, description: 'Bath') }

  describe '#data' do

    it 'gets collects all the import logs from the configs' do
      sheffield_import_log = create(:amr_data_feed_import_log, amr_data_feed_config: sheffield_config, records_imported: 200, import_time: 1.day.ago)
      bath_import_log = create(:amr_data_feed_import_log, amr_data_feed_config: bath_config, records_imported: 1, import_time: 1.day.ago)
      data = ImportNotifier.new.data(from: 2.days.ago, to: Time.now)
      expect(data[sheffield_config][:import_logs]).to eq([sheffield_import_log])
      expect(data[bath_config][:import_logs]).to eq([bath_import_log])
    end

    it 'restricts logs on the date' do
      sheffield_import_log = create(:amr_data_feed_import_log, amr_data_feed_config: sheffield_config, records_imported: 200, import_time: 1.day.ago)
      bath_import_log = create(:amr_data_feed_import_log, amr_data_feed_config: bath_config, records_imported: 1, import_time: 1.year.ago)
      data = ImportNotifier.new.data(from: 2.days.ago, to: Time.now)
      expect(data[sheffield_config][:import_logs]).to eq([sheffield_import_log])
      expect(data[bath_config][:import_logs]).to eq([])
    end

    it 'gets all the meters that have not had validated data for X days' do
      sheffield_import_log = create(:amr_data_feed_import_log, amr_data_feed_config: sheffield_config, records_imported: 200, import_time: 1.day.ago)
      meter_1 = create(:gas_meter_with_validated_reading_dates, :with_unvalidated_readings, start_date: 20.days.ago, end_date: 9.days.ago, config: sheffield_config, log: sheffield_import_log)
      meter_2 = create(:gas_meter_with_validated_reading_dates, :with_unvalidated_readings, start_date: 20.days.ago, end_date: 2.days.ago, config: sheffield_config, log: sheffield_import_log)
      data = ImportNotifier.new.data(from: 2.days.ago, to: Time.now)
      expect(data[sheffield_config][:import_logs]).to eq([sheffield_import_log])
      expect(data[sheffield_config][:meters_running_behind]).to match_array([meter_1])
    end

    it 'does not return any late meters if there is no day set' do
      sheffield_config.update!(import_warning_days: nil)
      sheffield_import_log = create(:amr_data_feed_import_log, amr_data_feed_config: sheffield_config, records_imported: 200, import_time: 1.day.ago)
      meter_1 = create(:gas_meter_with_validated_reading_dates, :with_unvalidated_readings, start_date: 20.days.ago, end_date: 9.days.ago, config: sheffield_config, log: sheffield_import_log)
      meter_2 = create(:gas_meter_with_validated_reading_dates, :with_unvalidated_readings, start_date: 20.days.ago, end_date: 2.days.ago, config: sheffield_config, log: sheffield_import_log)
      data = ImportNotifier.new.data(from: 2.days.ago, to: Time.now)
      expect(data[sheffield_config][:import_logs]).to eq([sheffield_import_log])
      expect(data[sheffield_config][:meters_running_behind]).to match_array([])
    end

    it 'gets all the meters from the imports where there is missing data' do
      sheffield_import_log = create(:amr_data_feed_import_log, amr_data_feed_config: sheffield_config, records_imported: 200, import_time: 1.day.ago)
      meter_1 = create(:gas_meter_with_validated_reading_dates, :with_unvalidated_readings, start_date: 20.days.ago, end_date: 2.days.ago, config: sheffield_config, log: sheffield_import_log)
      meter_2 = create(:gas_meter_with_validated_reading_dates, :with_unvalidated_readings, start_date: 20.days.ago, end_date: 2.days.ago, config: sheffield_config, log: sheffield_import_log)

      meter_1.amr_data_feed_readings.last.update!(readings: Array.new(48, ''))
      data = ImportNotifier.new.data(from: 2.days.ago, to: Time.now)
      expect(data[sheffield_config][:meters_with_blank_data]).to match_array([meter_1])
    end

    it 'gets all the meters from the imports where there is zero data' do
      sheffield_import_log = create(:amr_data_feed_import_log, amr_data_feed_config: sheffield_config, records_imported: 200, import_time: 1.day.ago)
      meter_1 = create(:gas_meter_with_validated_reading_dates, :with_unvalidated_readings, start_date: 20.days.ago, end_date: 2.days.ago, config: sheffield_config, log: sheffield_import_log)
      meter_2 = create(:gas_meter_with_validated_reading_dates, :with_unvalidated_readings, start_date: 20.days.ago, end_date: 2.days.ago, config: sheffield_config, log: sheffield_import_log)

      meter_1.amr_data_feed_readings.last.update!(readings: Array.new(48, 0))
      data = ImportNotifier.new.data(from: 2.days.ago, to: Time.now)
      expect(data[sheffield_config][:meters_with_zero_data]).to match_array([meter_1])
    end

    it 'does not include solar export with zero data' do
      sheffield_import_log = create(:amr_data_feed_import_log, amr_data_feed_config: sheffield_config, records_imported: 200, import_time: 1.day.ago)
      meter_1 = create(:exported_solar_pv_meter, :with_unvalidated_readings, start_date: 20.days.ago, end_date: 2.days.ago, config: sheffield_config, log: sheffield_import_log)

      meter_1.amr_data_feed_readings.last.update!(readings: Array.new(48, 0))
      data = ImportNotifier.new.data(from: 2.days.ago, to: Time.now)
      expect(data[sheffield_config][:meters_with_zero_data]).to be_empty
    end

  end


  describe '#notify' do
    it 'sends an email with the import count for each logged import with its config details' do
      create(:amr_data_feed_import_log, amr_data_feed_config: sheffield_config, records_imported: 200, import_time: 1.day.ago)
      create(:amr_data_feed_import_log, amr_data_feed_config: bath_config, records_imported: 1, import_time: 1.day.ago)

      ImportNotifier.new.notify(from: 2.days.ago, to: Time.now)

      email = ActionMailer::Base.deliveries.last

      expect(email.subject).to include('Energy Sparks import')
      expect(email.html_part.body.to_s).to include('Sheffield')
      expect(email.html_part.body.to_s).to include('200')
      expect(email.html_part.body.to_s).to include('Bath')
    end

    it 'can override the emails subject' do
      ImportNotifier.new(description: 'early morning import').notify(from: 2.days.ago, to: Time.now)
      email = ActionMailer::Base.deliveries.last
      expect(email.subject).to include('Energy Sparks early morning import')
    end
  end

end
