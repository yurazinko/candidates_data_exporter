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
    let(:path) { "#{base_url}job-applications?include=candidate" }

    context "when API returns success response" do
      let(:response_body) do
        {
          data: [ { id: "1", type: "job-application" } ],
          included: [ { id: "10", type: "candidate" } ]
        }.to_json
      end

      before do
        stub_request(:get, path)
          .with(
            headers: {
              "Authorization" => "Token token=#{api_key}",
              "X-Api-Version" => "20240404",
              "Content-Type" => "application/vnd.api+json"
            }
          )
          .to_return(status: 200, body: response_body)
      end

      it "returns parsed JSON" do
        result = client.fetch_candidates_and_applications
        expect(result["data"].first["id"]).to eq("1")
        expect(result["included"].first["id"]).to eq("10")
      end
    end

    context "when API returns non-success status" do
      before do
        stub_request(:get, path)
          .to_return(status: 500, body: { error: "fail" }.to_json)
      end

      it "raises InvalidResponseError" do
        expect {
          client.fetch_candidates_and_applications
        }.to raise_error(BaseApiClient::InvalidResponseError)
      end
    end

    context "when network timeout occurs" do
      before do
        stub_request(:get, path).to_timeout
      end

      it "raises NetworkError" do
        expect {
          client.fetch_candidates_and_applications
        }.to raise_error(BaseApiClient::NetworkError)
      end
    end

    context "when connection fails" do
      before do
        stub_request(:get, path).to_raise(Faraday::ConnectionFailed.new("connection failed"))
      end

      it "raises NetworkError" do
        expect {
          client.fetch_candidates_and_applications
        }.to raise_error(BaseApiClient::NetworkError)
      end
    end

    context "when API returns invalid JSON" do
      before do
        stub_request(:get, path)
          .to_return(status: 200, body: "invalid-json")
      end

      it "raises ParseError" do
        expect {
          client.fetch_candidates_and_applications
        }.to raise_error(BaseApiClient::ParseError)
      end
    end

    context "when headers are correctly applied" do
      before do
        stub_request(:get, path)
          .with(headers: {
            "Authorization" => "Token token=#{api_key}",
            "X-Api-Version" => "20240404",
            "Content-Type" => "application/vnd.api+json"
          })
          .to_return(status: 200, body: "{}")
      end

      it "sends proper headers" do
        client.fetch_candidates_and_applications
        expect(
          a_request(:get, path).with(
            headers: {
              "Authorization" => "Token token=#{api_key}",
              "X-Api-Version" => "20240404",
              "Content-Type" => "application/vnd.api+json"
            }
          )
        ).to have_been_made
      end
    end
  end
end
