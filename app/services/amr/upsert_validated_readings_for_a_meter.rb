module Amr
  class UpsertValidatedReadingsForAMeter
    NAN_READINGS = Array.new(48, Float::NAN).freeze

    def initialize(dashboard_meter)
      @dashboard_meter = dashboard_meter
    end

    def perform
      Rails.logger.info "Processing: #{@dashboard_meter} with mpan_mprn: #{@dashboard_meter.mpan_mprn} id: #{@dashboard_meter.external_meter_id}"
      amr_data = @dashboard_meter.amr_data

      validated_amr_data = amr_data.delete_if {|_reading_date, one_day_read| is_nan?(one_day_read) }

      Upsert.batch(AmrValidatedReading.connection, AmrValidatedReading.table_name) do |upsert|
        validated_amr_data.values.each do |one_day_read|
          upsert_from_one_day_reading(@dashboard_meter.external_meter_id, upsert, one_day_read)
        end
      end
      Rails.logger.info "Upserted: #{@dashboard_meter}"
      @dashboard_meter.amr_data = validated_amr_data
      @dashboard_meter
    end

  private

    def upsert_from_one_day_reading(meter_id, upsert, one_day_reading)
      upsert.row({ meter_id: meter_id, reading_date: one_day_reading.date },
        meter_id: meter_id,
        reading_date: one_day_reading.date,
        kwh_data_x48: one_day_reading.kwh_data_x48,
        one_day_kwh: one_day_reading.one_day_kwh,
        substitute_date: one_day_reading.substitute_date,
        status: one_day_reading.type,
        upload_datetime: one_day_reading.upload_datetime
      )
    end

    def is_nan?(one_day_reading)
      one_day_reading.one_day_kwh == Float::NAN || one_day_reading.kwh_data_x48 == NAN_READINGS
    end
  end
end
