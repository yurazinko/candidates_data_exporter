class BaseApiClient
  class InvalidResponseError < StandardError; end
  class NetworkError < StandardError; end
  class ParseError < StandardError; end

  def initialize
    @retry_options = default_retry_options
  end

  def perform_request(method: :get, path: "", params: {}, headers: {}, body: {})
    run_in_error_handler do
      @raw_response = connection.public_send(method, path) do |request|
        params.each  { |k, v| request.params[k]  = v }
        headers.each { |k, v| request.headers[k] = v }
        request.body = body.to_json
      end

      unless raw_response.success?
        raise InvalidResponseError, { message: "API Error: Failed to fetch #{path}", status: raw_response.status }
      end

      JSON.parse(raw_response.body).deep_transform_keys(&:underscore).deep_symbolize_keys
    end
  end

  private

  attr_reader :retry_options, :raw_response

  def connection
    @connection ||= Faraday.new(url: base_url) do |f|
      f.request :retry, retry_options
      f.options.timeout = 10
      f.options.open_timeout = 5
    end
  end

  def run_in_error_handler
    yield
  rescue Faraday::TimeoutError, Faraday::ConnectionFailed, Faraday::SSLError => e
    raise NetworkError, { message:  "Network failure: #{e.message}" }
  rescue Faraday::Error => e
    raise NetworkError, { message:  "Faraday error: #{e.message}" }
  rescue JSON::ParserError
    raise ParseError, { message:  "Invalid JSON in API response body" }
  end

  def default_retry_options
    {
      max: 5,
      interval: 0.05,
      interval_randomness: 0.5,
      backoff_factor: 2
    }
  end
end
