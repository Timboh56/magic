module LinkedinHelper
  require 'rubygems'
  require 'linkedin'

  class << self

    def request_token

      # If you want to use one of the scopes from linkedin you have to pass it in at this point
      # You can learn more about it here: http://developer.linkedin.com/documents/authentication
      @request_token ||= client.request_token({})

    end

    def client

      # get your api keys at https://www.linkedin.com/secure/developer
      @client ||= LinkedIn::Client.new('75jasbl9sxycjh', 'M8GjAeURO2gdlYG5')

    end

    def authorize_url

      # to test from your desktop, open the following url in your browser
      # and record the pin it gives you
      authorize_url = request_token.authorize_url
    end

    def init
      @client = client
      @request_token = request_token
      authorize
      # or authorize from previously fetched access keys

      # you're now free to move about the cabin, call any API method
    end

    def authorize
      client.authorize_from_request(request_token.token, request_token.secret,"12077")
    end

    def message(subject, body, ids)
      response = client.send_message(subject, body, ids)
    end
  end
end