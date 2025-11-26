class CandidatesDataTransformer
  def self.call(raw_data)
    new(raw_data).transform
  end

  def initialize(raw_data)
    @applications = raw_data[:data] || []
    @included = raw_data[:included] || []
  end

  def transform
    @applications.map do |application|
      candidate_id = application.dig(:relationships, :candidate, :data, :id)
      candidate_attributes = candidates_list[candidate_id]

      next unless candidate_attributes

      {
        candidate_id: candidate_id,
        first_name: candidate_attributes[:first_name],
        last_name: candidate_attributes[:last_name],
        email: candidate_attributes[:email],

        job_application_id: application[:id],
        job_application_created_at: Time.parse(application.dig(:attributes, :created_at)).strftime("%d.%m.%Y %H:%M:%S")
      }
    end.compact
  end

  private

  def candidates_list
    @candidates_list ||= @included.each_with_object({}) do |item, collected|
      collected[item[:id]] = item[:attributes] if item[:type] == "candidates"
    end
  end
end
