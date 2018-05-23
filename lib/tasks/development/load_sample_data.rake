namespace :development do
  desc 'Load sample usage data for 3 schools'
  task :load_sample_data, [:csv_file] => [:environment] do |_t, args|
    Loader::SampleDataLoader.load!(args[:csv_file])
  end

  task active_freshford_with_meters: [:environment] do
    school = School.find_by(urn: 109195)
    school.update(enrolled: true)
    Meter.create(school: school, meter_type: :gas, active: true, name: "Gas", meter_no: 67095200)
    Meter.create(school: school, meter_type: :electricity, active: true, name: "Electricity", meter_no: 2000006183919)
  end
end
