require 'rails_helper'

describe 'Meter', :meters do
  describe 'meter attributes' do
    let(:meter) { build(:electricity_meter) }

    it 'is not pseudo by default' do
      expect(meter.pseudo).to be false
    end

  end

  describe 'valid?' do
    describe 'mpan_mprn' do
      context 'with an electricity meter' do

        let(:attributes) {attributes_for(:electricity_meter)}

        it 'is valid with a 13 digit number' do
          meter = Meter.new(attributes.merge(mpan_mprn: 1098598765437))
          meter.valid?
          expect(meter.errors[:mpan_mprn]).to be_empty
        end

        it 'is valid with a 15 digit number' do
          meter = Meter.new(attributes.merge(mpan_mprn: 991098598765437))
          meter.valid?
          expect(meter.errors[:mpan_mprn]).to be_empty
        end

        it 'is invalid with a 16 digit number' do
          meter = Meter.new(attributes.merge(mpan_mprn: 9991098598765437))
          meter.valid?
          expect(meter.errors[:mpan_mprn]).to_not be_empty
        end

        it 'is invalid with a number less than 13 digits' do
          meter = Meter.new(attributes.merge(mpan_mprn: 123))
          meter.valid?
          expect(meter.errors[:mpan_mprn]).to_not be_empty
        end

      end

      context 'with a pseudo solar electricity meter' do

        let(:attributes) {attributes_for(:electricity_meter).merge(pseudo: true)}

        it 'is valid with a 14 digit number' do
          meter = Meter.new(attributes.merge(mpan_mprn: 91098598765437))
          meter.valid?
          expect(meter.errors[:mpan_mprn]).to be_empty
        end

        it 'is valid with non-standard 13 digit part' do
          meter = Meter.new(attributes.merge(mpan_mprn: 90000000000037))
          meter.valid?
          expect(meter.errors[:mpan_mprn]).to be_empty
        end

        it 'is invalid with a number less than 14 digits' do
          meter = Meter.new(attributes.merge(mpan_mprn: 1234))
          meter.valid?
          expect(meter.errors[:mpan_mprn]).to_not be_empty
        end

        it 'is invalid with a 14 digit number not beginning with 6,7,9' do
          meter = Meter.new(attributes.merge(mpan_mprn: 11098598765437))
          meter.valid?
          expect(meter.errors[:mpan_mprn]).to_not be_empty
        end
      end

      context 'with a solar pv meter' do

        let(:attributes) {attributes_for(:solar_pv_meter)}

        it 'is valid with a 14 digit number' do
          meter = Meter.new(attributes.merge(mpan_mprn: 12345678901234))
          meter.valid?
          expect(meter.errors[:mpan_mprn]).to be_empty
        end

        it 'is valid with a 15 digit number' do
          meter = Meter.new(attributes.merge(mpan_mprn: 123456789012345))
          meter.valid?
          expect(meter.errors[:mpan_mprn]).to be_empty
        end

        it 'is invalid with a number less than 13 digits' do
          meter = Meter.new(attributes.merge(mpan_mprn: 123456789012))
          meter.valid?
          expect(meter.errors[:mpan_mprn]).to_not be_empty
        end

        it 'is invalid with a number more than 15 digits' do
          meter = Meter.new(attributes.merge(mpan_mprn: 1234567890123456))
          meter.valid?
          expect(meter.errors[:mpan_mprn]).to_not be_empty
        end

      end

      context 'with an exported solar pv meter' do

        let(:attributes) {attributes_for(:exported_solar_pv_meter)}

        it 'is valid with a 14 digit number' do
          meter = Meter.new(attributes.merge(mpan_mprn: 61098598765437))
          meter.valid?
          expect(meter.errors[:mpan_mprn]).to be_empty
        end

        it 'is invalid with a number less than 13 digits' do
          meter = Meter.new(attributes.merge(mpan_mprn: 123456789012))
          meter.valid?
          expect(meter.errors[:mpan_mprn]).to_not be_empty
        end

      end

      context 'with a gas meter' do
        let(:attributes) {attributes_for(:gas_meter)}

        it 'is valid with a 10 digit number' do
          meter = Meter.new(attributes.merge(mpan_mprn: 1098598765))
          meter.valid?
          expect(meter.errors[:mpan_mprn]).to be_empty
        end

        it 'is invalid with a number longer than 15 digits' do
          meter = Meter.new(attributes.merge(mpan_mprn: 1234567890123456))
          meter.valid?
          expect(meter.errors[:mpan_mprn]).to_not be_empty
        end

      end
    end
  end

  describe 'correct_mpan_check_digit?' do
    it 'returns true if the check digit matches' do
      meter = Meter.new(meter_type: :electricity, mpan_mprn: 2040015001169)
      expect(meter.correct_mpan_check_digit?).to eq(true)
    end

    it 'returns true if the check digit matches ignoring prepended digit for electricity meters' do
      meter = Meter.new(meter_type: :electricity, mpan_mprn: 92040015001169)
      expect(meter.correct_mpan_check_digit?).to eq(true)
    end

    it 'returns true if the check digit matches ignoring 2 prepended digits for electricity meters' do
      meter = Meter.new(meter_type: :electricity, mpan_mprn: 992040015001169)
      expect(meter.correct_mpan_check_digit?).to eq(true)
    end

    it 'returns false if the check digit does not match' do
      meter = Meter.new(meter_type: :electricity, mpan_mprn: 2040015001165)
      expect(meter.correct_mpan_check_digit?).to eq(false)
    end

    it 'returns false if the mpan is short' do
      meter = Meter.new(meter_type: :electricity, mpan_mprn: 2040015165)
      expect(meter.correct_mpan_check_digit?).to eq(false)
    end
  end

  describe '#last_validated_reading' do
    it "should find latest reading" do
      reading = create(:amr_validated_reading, reading_date: Date.parse('2018-12-01'))
      meter = reading.meter

      expect(meter.last_validated_reading).to eql(reading.reading_date)

      today = create(:amr_validated_reading, meter: meter, reading_date: Date.parse('2018-12-03'))
      create(:amr_validated_reading, meter: meter, reading_date: Date.parse('2018-12-02'))

      expect(meter.last_validated_reading).to eql(today.reading_date)
    end
  end

  describe '#first_validated_reading' do
    it "should find first reading" do
      reading = create(:amr_validated_reading, reading_date: Date.parse('2018-12-02'))
      meter = reading.meter

      expect(meter.first_validated_reading).to eql(reading.reading_date)

      today = create(:amr_validated_reading, meter: meter, reading_date: Date.parse('2018-12-03'))
      old_one = create(:amr_validated_reading, meter: meter, reading_date: Date.parse('2018-12-01'))

      expect(meter.first_validated_reading).to eql(old_one.reading_date)
    end
  end

  describe '#missing_validated_reading_dates' do

    let(:meter) { create(:electricity_meter) }

    it "should find total missing readings" do
      create(:amr_validated_reading, meter: meter, reading_date: Date.parse('2018-12-05'))
      create(:amr_validated_reading, meter: meter, reading_date: Date.parse('2018-12-07'))
      create(:amr_validated_reading, meter: meter, reading_date: Date.parse('2018-12-09'))

      expect(meter.missing_validated_reading_dates.count).to eql(2)
      expect(meter.missing_validated_reading_dates).to match_array([Date.parse('2018-12-06'), Date.parse('2018-12-08')])
    end
  end
end
