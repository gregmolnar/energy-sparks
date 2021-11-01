require 'rails_helper'

module Cads
  describe LiveDataService do

    let(:token)               { 'abc123' }
    let(:device_identifier)   { 'xyz' }
    let(:school)              { create(:school) }
    let(:cad)                 { create(:cad, school: school, device_identifier: device_identifier) }

    context 'when api returns response' do

      before :each do
        expect_any_instance_of(MeterReadingsFeeds::GeoApi).to receive(:login).and_return(token)
      end

      it "triggers fast update if no timestamp returned" do
        response = { 'powerTimestamp' => 0 }
        expect_any_instance_of(MeterReadingsFeeds::GeoApi).to receive(:live_data).with(cad.device_identifier).and_return(response)
        expect_any_instance_of(MeterReadingsFeeds::GeoApi).to receive(:trigger_fast_update).with(cad.device_identifier)
        result = Cads::LiveDataService.new(cad).read
        expect(result).to eq(0.0)
      end

      it "returns power reading" do
        response = { 'powerTimestamp' => 123, 'power' => [{'type' => 'ELECTRICITY', 'watts' => 456}] }
        expect_any_instance_of(MeterReadingsFeeds::GeoApi).to receive(:live_data).with(cad.device_identifier).and_return(response)
        result = Cads::LiveDataService.new(cad).read
        expect(result).to eq(456.0)
      end

      it "handles missing power reading for other type" do
        response = { 'powerTimestamp' => 123, 'power' => [{'type' => 'ELECTRICITY', 'watts' => 456}] }
        expect_any_instance_of(MeterReadingsFeeds::GeoApi).to receive(:live_data).with(cad.device_identifier).and_return(response)
        result = Cads::LiveDataService.new(cad).read(:gas)
        expect(result).to eq(0.0)
      end
    end

    context 'when api raises errors' do

      before :each do
        expect_any_instance_of(MeterReadingsFeeds::GeoApi).to receive(:login).and_raise(StandardError.new('doh'))
      end

      it "logs error to rollbar" do
        expect(Rollbar).to receive(:error)
        result = Cads::LiveDataService.new(cad).read
      end
    end

    context 'when caching tokens' do

      it "caches token for default period" do
        expect(Rails.cache).to receive(:fetch).with(LiveDataService::CACHE_KEY, expires_in: 45.minutes)
        Cads::LiveDataService.new(cad).read
      end

      it "caches token for env var period" do
        expect(Rails.cache).to receive(:fetch).with(LiveDataService::CACHE_KEY, expires_in: 123.minutes)
        ClimateControl.modify "GEO_API_TOKEN_EXPIRY_MINUTES" => "123" do
          Cads::LiveDataService.new(cad).read
        end
      end

    end
  end
end
