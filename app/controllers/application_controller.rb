class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  helper_method :current_user
  before_action :set_title
  layout "home"

  rescue_from Exception, with: :show_errors

  def set_title
  	@title = "ScrapeApe"
  end

  def current_user
  	@current_user ||= User.find(session[:user_id]["$oid"]) if session[:user_id]
  end

  private

  def show_errors(e)
    @errors = "Error(s): " + e.message
    puts @errors
    respond_to do |format|
      format.js { render :partial => "shared/errors.js", status: :unprocessable_entity }
      format.html { redirect_to request.env["HTTP_REFERER"] || root_url, status: :unprocessable_entity }
    end
  end
end
