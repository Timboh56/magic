OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, "1SzfIhMcCxz5UwfhT6RlC7hON", "smg6wZaOVcyTOp4dBQawnIE1E6XWs5SjCzemQXiK3r7gfiPYoL"
end
