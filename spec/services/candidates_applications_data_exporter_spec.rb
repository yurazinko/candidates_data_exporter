require "rails_helper"
require "tempfile"
require "base64"

RSpec.describe CandidatesApplicationsDataExporter do
  let(:exporter_error) { CandidatesApplicationsDataExporter::ExportFailedError }

  let(:api_client) { instance_double(TeamtailorApiClient) }
  let(:transformer) { class_double(CandidatesDataTransformer) }
  let(:csv_generator) { class_double(CsvGenerator) }

  let(:csv_generator_error) { Class.new(StandardError) }

  let(:raw_data) { { "data" => [], "included" => [] } }
  let(:transformed_data) { [ { "candidate_id" => 1, "first_name" => "Test" } ] }

  RAW_CSV_CONTENT =
    "Candidate ID,First Name,Last Name,Email,Job Application ID,Job Application Created At\r\n1,Test,,,,, \r\n"

  ENCODED_CSV_CONTENT = Base64.strict_encode64(RAW_CSV_CONTENT)


  subject(:exporter) { described_class.new }

  before do
    allow(TeamtailorApiClient).to receive(:new).and_return(api_client)

    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)

    stub_const("CandidatesDataTransformer", transformer)

    stub_const("CsvGenerator", csv_generator)
    stub_const("CsvGenerator::CsvGenerationError", csv_generator_error)

    allow(api_client).to receive(:fetch_candidates_and_applications).and_return(raw_data)
    allow(transformer).to receive(:call).with(raw_data).and_return(transformed_data)
  end

  context "when the export process is successful" do
    before do
      allow(csv_generator).to receive(:generate).and_return(RAW_CSV_CONTENT)
    end

    it "calls API client, transformer, and CSV generator in correct order" do
      exporter.run_export

      expect(api_client).to have_received(:fetch_candidates_and_applications).ordered
      expect(transformer).to have_received(:call).with(raw_data).ordered

      expect(csv_generator).to have_received(:generate).with(
        transformed_data,
        described_class::EXPORT_SCHEMA,
      ).ordered
    end

    it "returns the Base64 encoded CSV content" do
      result = exporter.run_export
      expect(result).to eq(ENCODED_CSV_CONTENT)
    end
  end

  context "when CsvGenerator fails" do
    let(:csv_error_message) { "Internal generation error" }

    before do
      allow(csv_generator).to receive(:generate).and_raise(
        csv_generator_error, csv_error_message
      )
    end

    it "raises ExportFailedError and includes the CSV error message" do
      expect {
        exporter.run_export
      }.to raise_error(exporter_error, /Failed to export data to CSV: Internal generation error/)
    end

    it "does not call CsvGenerator if API or transformer fails (implied by execution order)" do
      api_client_error = Class.new(StandardError)
      stub_const("TeamtailorApiClient::NetworkError", api_client_error)

      allow(api_client).to receive(:fetch_candidates_and_applications).and_raise(api_client_error, "API Error")

      expect {
        exporter.run_export
      }.to raise_error(api_client_error, "API Error")

      expect(csv_generator).not_to have_received(:generate)
    end
  end

  context "when API client or transformer fails" do
    let(:api_client_error_class) { Class.new(StandardError) }

    before do
      stub_const("TeamtailorApiClient::NetworkError", api_client_error_class)
    end

    it "raises the original API error without masking it" do
      api_client_error = api_client_error_class.new("Timeout occurred")
      allow(api_client).to receive(:fetch_candidates_and_applications).and_raise(api_client_error)

      expect {
        exporter.run_export
      }.to raise_error(api_client_error)
    end

    it "raises the original transformer error without masking it" do
      transformer_error = StandardError.new("Missing key in attributes")
      allow(transformer).to receive(:call).and_raise(transformer_error)

      expect {
        exporter.run_export
      }.to raise_error(transformer_error)
    end
  end
end
