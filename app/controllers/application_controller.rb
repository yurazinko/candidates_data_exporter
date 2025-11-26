class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  rescue_from StandardError, with: :handle_internal_server_error

  def handle_internal_server_error(exception)
    Rails.logger.fatal "UNEXPECTED FATAL ERROR: #{exception.message}"
    Rails.logger.fatal exception.backtrace.join("\n")

    render json: {
      status: "error",
      message: "An unexpected internal error occurred.",
      code: "internal_server_error"
    }, status: :internal_server_error
  end
end
