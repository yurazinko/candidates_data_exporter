class BaseApiClient
  class InvalidResponseError < StandardError; end
  class NetworkError < StandardError; end
  class ParseError < StandardError; end

  def perform_request(method: :get, path: "", params: {}, headers: {}, body: {})
    run_in_error_handler do
      @raw_response = connection.public_send(method, path) do |request|
        params.each  { |k, v| request.params[k]  = v }
        headers.each { |k, v| request.headers[k] = v }
        request.body = body.to_json
      end

      unless raw_response.success?
        raise InvalidResponseError, "API Error with status #{raw_response.status}: Failed to fetch #{path}"
      end

      JSON.parse(raw_response.body)
    end
  end

  private

  attr_reader :raw_response

  def connection
    @connection ||= Faraday.new(url: base_url)
  end

  def run_in_error_handler
    yield
  rescue Faraday::TimeoutError, Faraday::ConnectionFailed, Faraday::SSLError => e
    raise NetworkError, "Network failure: #{e.message}"
  rescue Faraday::Error => e
    raise NetworkError, "Faraday error: #{e.message}"
  rescue JSON::ParserError
    raise ParseError, "Invalid JSON in API response body"
  end
end
