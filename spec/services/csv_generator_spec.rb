require "rails_helper"
require "csv"
require "stringio"

RSpec.describe CsvGenerator do
  before do
    stub_const("CsvGenerator::CsvGenerationError", Class.new(StandardError))
    allow(Rails.logger).to receive(:error)
  end

  let(:config_schema) do
    [
      { header: "ID", field: :id },
      { header: "Name", field: :name },
      { header: "Value", field: :value }
    ]
  end

  let(:test_data) do
    [
      { id: 1, name: "Alpha", value: 100 },
      { id: 2, name: "Beta", value: 200 },
      { id: 3, name: "Gamma", value: nil }
    ]
  end

  describe ".generate" do
    context "when successful" do
      let(:expected_csv) do
        "ID,Name,Value\n1,Alpha,100\n2,Beta,200\n3,Gamma,\n"
      end

      it "returns the correct CSV content as a string" do
        result = described_class.generate(test_data, config_schema)
        expect(result).to eq(expected_csv)
      end

      it "handles empty data gracefully" do
        empty_data = []
        expected_empty_csv = "ID,Name,Value\n"

        result = described_class.generate(empty_data, config_schema)
        expect(result).to eq(expected_empty_csv)
      end

      it "handles nil values in data" do
        result = described_class.generate(test_data, config_schema)
        expect(result).to include("3,Gamma,\n")
      end
    end

    context "when a general error occurs during processing" do
      before do
        allow(config_schema).to receive(:map).and_raise(StandardError, "Schema processing failed")
      end

      it "raises a CsvGenerationError" do
        expect {
          described_class.generate(test_data, config_schema)
        }.to raise_error(CsvGenerator::CsvGenerationError, /Failed to generate CSV: Schema processing failed/)
      end

      it "logs the underlying error" do
        expect {
          described_class.generate(test_data, config_schema)
        }.to raise_error(CsvGenerator::CsvGenerationError)

        expect(Rails.logger).to have_received(:error).with(/CSV generation failed: Schema processing failed/)
      end
    end
  end
end
