class TeamtailorApiClient < BaseApiClient
  ITEMS_PER_PAGE = 30
  CACHE_KEY = "teamtailor/candidates_and_applications".freeze
  CACHE_TTL = 1.hour

  def fetch_candidates_and_applications
    Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_TTL) do
      all_data = { data: [], included: [] }

      current_path = "job-applications?page[size]=#{ITEMS_PER_PAGE}&include=candidate"

      while current_path
        Rails.logger.info "CACHE MISS: Fetching: #{current_path}"
        response = perform_request(path: current_path, headers: request_headers)

        all_data[:data].concat(response[:data] || [])
        all_data[:included].concat(response[:included] || [])

        current_path = response.dig(:links, :next)
      end

      all_data
    end
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

  def request_headers
    @request_headers ||= {
      "Authorization" => "Token token=#{api_key}",
      "X-Api-Version" => "20240404",
      "Content-Type" => "application/vnd.api+json"
    }
  end

  def default_retry_options
    super.merge!({
      retry_statuses: [ 429, 500, 502, 503, 504 ],
      rate_limit_reset_header: "x-rate-limit-reset",
      header_parser_block: ->(value) { value.to_i }
    })
  end
end
