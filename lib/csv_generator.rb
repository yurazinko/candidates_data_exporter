class CsvGenerator
  class CsvGenerationError < StandardError; end


  def self.generate(data, config_schema)
    csv_string = StringIO.new
    headers = config_schema.map { |item| item[:header] }

    CSV.open(csv_string, "w") do |csv|
      csv << headers

      data.each do |data_item|
        row = config_schema.map do |config|
          data_item[config[:field]]
        end

        csv << row
      end
    end

    csv_string.string
  rescue StandardError => e
    Rails.logger.error "CSV generation failed: #{e.message}"
    raise CsvGenerationError, "Failed to generate CSV: #{e.message}"
  end
end
