class Api::BaseController < ApplicationController
  protect_from_forgery with: :null_session
  
  before_action :set_content_type

  private

  def set_content_type
    response.headers['Content-Type'] = 'application/json'
  end
end
