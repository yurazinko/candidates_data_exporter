require "rails_helper"

RSpec.describe TeamtailorApiClient do
  let(:base_url) { "https://api.teamtailor.com/" }
  let(:api_key)  { "secret123" }

  let(:client)   { described_class.new }

  before do
    allow(ENV).to receive(:[]).and_call_original

    allow(ENV).to receive(:[]).with("TEAMTAILOR_API_BASE_URL").and_return(base_url)
    allow(ENV).to receive(:[]).with("TEAMTAILOR_API_KEY").and_return(api_key)
  end

  describe "#fetch_candidates_and_applications" do
    let(:default_path) { "#{base_url}job-applications?page[size]=30&include=candidate" }

    context "with successful single-page response" do
      let(:response_body) do
        {
          data: [ { id: "1", type: "job-application" } ],
          included: [ { id: "10", type: "candidate" } ],
          links: { next: nil }
        }.to_json
      end

      before do
        stub_request(:get, default_path)
          .with(headers: {
            "Authorization"  => "Token token=#{api_key}",
            "X-Api-Version"  => "20240404",
            "Content-Type"   => "application/vnd.api+json"
          })
          .to_return(status: 200, body: response_body)
      end

      it "returns merged data and included arrays" do
        result = client.fetch_candidates_and_applications

        expect(result[:data].size).to eq(1)
        expect(result[:included].size).to eq(1)
      end
    end

    context "with paginated responses" do
      let(:first_body) do
        {
          data: [ { id: "1" } ],
          included: [ { id: "10" } ],
          links: { next: "job-applications?page[size]=30&page[number]=2&include=candidate" }
        }.to_json
      end

      let(:second_body) do
        {
          data: [ { id: "2" } ],
          included: [ { id: "11" } ],
          links: { next: nil }
        }.to_json
      end

      before do
        stub_request(:get, default_path)
          .to_return(status: 200, body: first_body)

        stub_request(:get, "#{base_url}job-applications?page[size]=30&page[number]=2&include=candidate")
          .to_return(status: 200, body: second_body)
      end

      it "fetches both pages and merges results" do
        result = client.fetch_candidates_and_applications

        expect(result[:data].map { |i| i[:id] }).to eq([ "1", "2" ])
        expect(result[:included].map { |i| i[:id] }).to eq([ "10", "11" ])
      end
    end

    context "when API returns a non-success status" do
      before do
        stub_request(:get, default_path)
          .to_return(status: 500, body: "{}")
      end

      it "raises InvalidResponseError" do
        expect {
          client.fetch_candidates_and_applications
        }.to raise_error(BaseApiClient::InvalidResponseError)
      end
    end

    context "when Faraday raises a network error" do
      before do
        stub_request(:get, default_path)
          .to_raise(Faraday::TimeoutError)
      end

      it "raises NetworkError" do
        expect {
          client.fetch_candidates_and_applications
        }.to raise_error(BaseApiClient::NetworkError)
      end
    end

    context "when API returns invalid JSON" do
      before do
        stub_request(:get, default_path)
          .to_return(status: 200, body: "invalid-json")
      end

      it "raises ParseError" do
        expect {
          client.fetch_candidates_and_applications
        }.to raise_error(BaseApiClient::ParseError)
      end
    end
  end
end
