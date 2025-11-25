require "rails_helper"

RSpec.describe CandidatesDataTransformer do
  let(:raw_data_fixture) do
    {
      data: [
        {
          id: "29305118",
          type: "job-applications",
          attributes: { created_at: "2022-03-22T15:59:12.658+01:00" },
          relationships: { candidate: { data: { id: "CAND_1", type: "candidates" } } }
        },
        {
          id: "29305121",
          type: "job-applications",
          attributes: { created_at: "2022-03-22T16:00:00.000+01:00" },
          relationships: { candidate: { data: nil } }
        },
        {
          id: "29305122",
          type: "job-applications",
          attributes: { created_at: "2022-03-22T16:01:00.000+01:00" },
          relationships: { candidate: { data: { id: "CAND_3", type: "candidates" } } }
        }
      ],
      included: [
        {
          id: "CAND_1",
          type: "candidates",
          attributes: {
            first_name: "John",
            last_name: "Doe",
            email: "john.doe@example.com"
          }
        },
        {
          id: "JOB_2",
          type: "jobs",
          attributes: { title: "Engineer" }
        }
      ]
    }
  end

  describe ".call" do
    it "returns the transformed array when all data is present" do
      result = described_class.call(raw_data_fixture)

      expect(result.size).to eq(1)

      first_record = result.first

      expect(first_record[:candidate_id]).to eq("CAND_1")
      expect(first_record[:first_name]).to eq("John")
      expect(first_record[:last_name]).to eq("Doe")
      expect(first_record[:email]).to eq("john.doe@example.com")

      expect(first_record[:job_application_id]).to eq("29305118")
      expect(first_record[:job_application_created_at]).to eq("2022-03-22T15:59:12.658+01:00")
    end

    it "handles empty input data gracefully" do
      empty_data = { data: [], included: [] }
      expect(described_class.call(empty_data)).to eq([])
    end

    it "handles nil input data gracefully" do
      expect(described_class.call({})).to eq([])
    end

    it "compacts records where candidate link is missing" do
      result = described_class.call(raw_data_fixture)
      expect(result.map { |r| r[:job_application_id] }).not_to include("29305121")
    end

    it "compacts records where candidate is not included in the response" do
      result = described_class.call(raw_data_fixture)

      expect(result.map { |r| r[:job_application_id] }).not_to include("29305122")
    end
  end
end
