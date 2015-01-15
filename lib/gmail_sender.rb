module GmailSender
  require "gmail"

  def self.send_email(username, password, to, msg, subj)
    gmail = Gmail.new(username, password)
    
    gmail.deliver do
      to to
      subject subj
      text_part do
        body msg
      end
      html_part do
        content_type 'text/html; charset=UTF-8'
        body msg
      end
    end

    # ...do things...
    gmail.logout

  end
end