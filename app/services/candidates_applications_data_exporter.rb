
class CandidatesApplicationsDataExporter
  class ExportFailedError < StandardError; end

  FILE_OUTPUT_PATH = "#{Rails.root.join("tmp")}/#{Time.zone.now.to_s.parameterize}.csv".freeze
  EXPORT_SCHEMA = [
    { header: "Candidate ID",               field: :candidate_id },
    { header: "First Name",                 field: :first_name },
    { header: "Last Name",                  field: :last_name },
    { header: "Email",                      field: :email },
    { header: "Job Application ID",         field: :job_application_id },
    { header: "Job Application Created At", field: :job_application_created_at }
  ].freeze

  def self.call(output_path = FILE_OUTPUT_PATH)
    new.run_export(output_path)
  end

  def initialize
    @api_client = TeamtailorApiClient.new
  end

  def run_export(output_path)
    Rails.logger.info "Starting Teamtailor candidate export..."

    raw_data = @api_client.fetch_candidates_and_applications

    transformed_data = CandidatesDataTransformer.call(raw_data)

    generated_file = CsvGenerator.generate(
      transformed_data,
      EXPORT_SCHEMA,
      output_path
    )

    generated_file
  rescue CsvGenerator::CsvGenerationError => e
    raise ExportFailedError, { message: "Failed to export data to CSV: #{e.message}" }
  end
end
