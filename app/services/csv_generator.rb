class CsvGenerator
  class CsvGenerationError < StandardError; end

  MIN_SIZE_BYTES = 15

  def self.generate(data, config_schema, file_path)
    headers = config_schema.map { |item| item[:header] }

    CSV.open(file_path, "wb") do |csv|
      csv << headers

      data.each do |data_item|
        row = config_schema.map do |config|
          data_item[config[:field]]
        end

        csv << row
      end
    end

    unless File.exist?(file_path) && File.size(file_path) > MIN_SIZE_BYTES
      Rails.logger.error "CSV generation failed silently: File is missing or too small."

      FileUtils.rm_f(file_path) if File.exist?(file_path)
      raise CsvGenerationError, "File generation failed integrity check (empty or missing file)."
    end

    file_path
  rescue StandardError => e
    Rails.logger.error "CSV generation failed: #{e.message}"
    raise CsvGenerationError, "Failed to generate CSV: #{e.message}"
  end
end
