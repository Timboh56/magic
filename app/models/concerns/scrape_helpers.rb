module ScrapeHelpers
  require 'deathbycaptcha'

  def death_by_captcha_client
    @client ||= DeathByCaptcha.http_client('timboh56', 'PlmOknIjb987')
    @client.config.is_verbose = true
    @client
  end

  def decode_captcha(captcha)
    response = death_by_captcha_client.decode captcha
  end

  def sleep_random
    sleep(rand(8))
  end
end