require 'rails_helper'
require 'base64'

RSpec.describe ExportsController, type: :controller do
  let(:raw_api_data) do
    {
      "data" => [
        {
          "id" => "29305118",
          "type" => "job-applications",
          "attributes" => { "created-at" => "2022-03-22T15:59:12.658+01:00" },
          "relationships" => { "candidate" => { "data" => { "id" => "CAND_1", "type" => "candidates" } } }
        },
        {
          "id" => "29305122",
          "type" => "job-applications",
          "attributes" => { "created-at" => "2022-03-22T16:01:00.000+01:00" },
          "relationships" => { "candidate" => { "data" => { "id" => "CAND_3_MISSING", "type" => "candidates" } } }
        }
      ],
      "included" => [
        {
          "id" => "CAND_1",
          "type" => "candidates",
          "attributes" => {
            "first-name" => "John",
            "last-name" => "Doe",
            "email" => "john.doe@example.com"
          }
        },
        { "id" => "JOB_2", "type" => "jobs", "attributes" => { "title" => "Engineer" } }
      ]
    }
  end

  let(:expected_raw_csv) do
    "Candidate ID,First Name,Last Name,Email,Job Application ID,Job Application Created At\n" \
     "CAND_1,John,Doe,john.doe@example.com,29305118,22.03.2022 15:59:12\n"
  end

  let(:api_client) { TeamtailorApiClient.new }

  let(:teamtailor_api_url) do
    "https://api.teamtailor.com/v1/job-applications?fields%5Bcandidates%5D=first-name,last-name,email&fields%5Bjob-applications%5D=created-at,candidate&include=candidate&page%5Bsize%5D=30"
  end

  before do
    allow(Rails.logger).to receive(:fatal)
    allow(Rails.logger).to receive(:error)
    allow(Rails.logger).to receive(:info)
  end

  after do
    Rails.cache.clear
  end

  describe "POST #create" do
    context "when export is successful" do
      before do
        stub_request(:get, teamtailor_api_url)
          .to_return(
            status: 200,
            body: raw_api_data.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it "returns 200 OK with the correct Base64 encoded content" do
        post :create

        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expected_encoded_content = Base64.strict_encode64(expected_raw_csv.encode("UTF-8"))

        expect(json_response["content"]).to eq(expected_encoded_content)

        expect(WebMock).to have_requested(:get, teamtailor_api_url).once
      end
    end

    context "when API returns an error status" do
      before do
        stub_request(:get, teamtailor_api_url)
          .to_return(
            status: 403,
            body: { error: "Access Denied" }.to_json
          )

        mock_api_client = instance_double(TeamtailorApiClient)
        allow(TeamtailorApiClient).to receive(:new).and_return(mock_api_client)

        allow(mock_api_client).to receive(:fetch_candidates_and_applications)
          .and_raise(TeamtailorApiClient::InvalidResponseError, "Something went wrong")
      end

      it "rescues with ApplicationController and returns 500" do
        post :create
        expect(response).to have_http_status(:internal_server_error)

        json_response = JSON.parse(response.body)

        expect(json_response["status"]).to eq("error")
        expect(Rails.logger).to have_received(:fatal).with(/UNEXPECTED FATAL ERROR: Something went wrong/)
      end
    end

    context "when a network error (timeout) occurs" do
      before do
        stub_request(:get, teamtailor_api_url).to_timeout

        mock_api_client = instance_double(TeamtailorApiClient)
        allow(TeamtailorApiClient).to receive(:new).and_return(mock_api_client)
        allow(mock_api_client).to receive(:fetch_candidates_and_applications)
          .and_raise(TeamtailorApiClient::NetworkError, "Connection timeout")
      end

      it "rescues with ApplicationController and returns 500" do
        post :create

        expect(response).to have_http_status(:internal_server_error)

        json_response = JSON.parse(response.body)

        expect(json_response["status"]).to eq("error")
        expect(Rails.logger).to have_received(:fatal).with(/UNEXPECTED FATAL ERROR: Connection timeout/)
      end
    end
  end
end
