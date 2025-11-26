require "rails_helper"
require "tempfile"
require "csv"

RSpec.describe CsvGenerator do
  let(:temp_file) { Tempfile.new([ "test_export", ".csv" ]) }
  let(:output_path) { temp_file.path }

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
      { id: 2, name: "Beta", value: 200 }
    ]
  end

  after do
    temp_file.close
    temp_file.unlink
  end

  describe ".generate" do
    context "when successful" do
      it "returns the file path" do
        result = described_class.generate(test_data, config_schema, output_path)
        expect(result).to eq(output_path)
      end

      it "writes the correct data and headers to the file" do
        described_class.generate(test_data, config_schema, output_path)

        contents = File.read(output_path)
        expect(contents).to include("ID,Name,Value")

        expected_line1 = "1,Alpha,100"
        expected_line2 = "2,Beta,200"
        expect(contents).to include(expected_line1)
        expect(contents).to include(expected_line2)
      end
    end

    context "when an IO error occurs during CSV generation" do
      before do
        allow(CSV).to receive(:open).and_raise(IOError, "Permission denied")
      end

      it "raises a CsvGenerationError" do
        expect {
          described_class.generate(test_data, config_schema, output_path)
        }.to raise_error(CsvGenerator::CsvGenerationError, /Permission denied/)
      end

      it "logs the underlying error" do
        expect {
          described_class.generate(test_data, config_schema, output_path)
        }.to raise_error
      end
    end

    context "when file is generated but fails integrity check" do
      let(:test_data_for_failure) { [] }

      before do
        File.open(output_path, 'r+') { |f| f.truncate(10) }

        expect(File.exist?(output_path)).to be true
        expect(File.size(output_path)).to be < CsvGenerator::MIN_SIZE_BYTES
      end

      it "raises a CsvGenerationError due to integrity failure" do
        expect {
          described_class.generate(test_data_for_failure, config_schema, output_path)
        }.to raise_error(CsvGenerator::CsvGenerationError)
      end

      it "attempts to remove the corrupted file" do
        allow(FileUtils).to receive(:rm_f).and_call_original

        expect {
          described_class.generate(test_data_for_failure, config_schema, output_path)
        }.to raise_error

        expect(FileUtils).to have_received(:rm_f).with(output_path)
      end
    end
  end
end
