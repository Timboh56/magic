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

  def check_current_user
    if current_user.nil?
      raise "You must be signed into twitter!"
    end
  end

  def send_email
    e = Email.new(
      email_type: "Client",
      body: params[:body],
      name: params[:name],
      email: params[:email]
    )
    
    if e.save
      UserMailer.send_email(e).deliver!
      render partial: "shared/email_success.js"
    else
      @errors = e.errors.full_messages.join(", ")
      render partial: "shared/errors.js", locals: { flash_container: ".flash-messages-email"}
    end
  end

  private

  def show_errors(e)
    @errors = "Error(s): " + e.message
    p @errors.inspect
    redirect_to root_url
  end
end
