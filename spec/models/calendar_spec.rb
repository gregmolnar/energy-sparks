require 'rails_helper'

describe Calendar do
  include_context 'calendar data'

  describe 'does lots of good calendar work' do

    it 'creates a calendar with academic years' do
      expect(calendar.calendar_events.count).to be 6
      expect(calendar.holidays.count).to be 3
      expect(calendar.bank_holidays.count).to be 1
    end

    it 'creates a holiday between the terms' do
      expect(calendar.calendar_events.count).to be 6
      does_holiday_fit_space_between_terms?(calendar)
    end

    def does_holiday_fit_space_between_terms?(calendar)
      expect(calendar.holidays.first.start_date).to eq calendar.terms.first.end_date + 1.day
      expect(calendar.holidays.first.end_date).to eq calendar.terms.second.start_date - 1.day
    end
  end

  describe 'it knows when alert triggers are coming up' do
    it 'knows when the next holiday is' do
      Timecop.freeze(Date.parse(autumn_term_half_term_holiday_start) - 1.week) do
        expect(calendar.next_holiday.start_date.to_s(:db)).to eq autumn_term_half_term_holiday_start
      end

      Timecop.freeze(Date.parse(random_before_holiday_start_date) - 1.week) do
        expect(calendar.next_holiday.start_date).to eq random_before_holiday.start_date
      end

      Timecop.freeze(Date.parse(random_after_holiday_start_date) - 1.week) do
        expect(calendar.next_holiday.start_date).to eq random_after_holiday.start_date
      end
    end

    it 'knows there is a holiday approaching' do
      holiday_start_date = Date.parse(autumn_terms[0][:end_date]) + 1.day

      Timecop.freeze(holiday_start_date - 1.week) do
        expect(calendar.holiday_approaching?).to be false
      end

      Timecop.freeze(holiday_start_date - 3.days) do
        expect(calendar.holiday_approaching?).to be true
      end

      Timecop.freeze(holiday_start_date - 2.days) do
        expect(calendar.holiday_approaching?).to be false
      end
    end
  end
end
