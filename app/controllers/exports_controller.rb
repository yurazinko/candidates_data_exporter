class ExportsController < ApplicationController
  def create
    render json: {
      filename: "candidates_export_#{Time.zone.now.to_s.parameterize}.csv",
      content: CandidatesApplicationsDataExporter.call
    }, status: :ok
  end
end
