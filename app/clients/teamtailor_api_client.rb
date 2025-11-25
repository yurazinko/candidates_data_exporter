class TeamtailorApiClient < BaseApiClient
  def fetch_candidates_and_applications
    perform_request(path: "job-applications?include=candidate", headers: headers)
  end

  private

  def base_url
    @base_url ||=
      ENV["TEAMTAILOR_API_BASE_URL"] || Rails.application.credentials.teamtailor_api[:base_url]
  end

  def api_key
    @api_key ||=
      ENV["TEAMTAILOR_API_KEY"] || Rails.application.credentials.teamtailor_api[:api_key]
  end

  def headers
    @headers ||= {
      "Authorization" => "Token token=#{api_key}",
      "X-Api-Version" => "20240404",
      "Content-Type" => "application/vnd.api+json"
    }
  end
end
