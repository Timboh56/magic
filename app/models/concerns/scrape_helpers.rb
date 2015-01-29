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

  def mechanize_agent
    @agent ||= lambda {
      agent = Mechanize.new
      set_proxy(agent)
      agent
    }.call
  end
  
  def set_proxy(agent)
    proxies = ProxyHost.all
    random_proxy = proxies[rand(proxies.count)]
    agent.set_proxy random_proxy.ip, random_proxy.port
    p "Proxy set: #{ random_proxy.ip }:#{ random_proxy.port }"
    agent
  end

  def find_form_button(agent, opts)
    form_btn = nil
    agent.page.forms.each do |form|
      if (btn = form.button_with(opts)).present?
        form_btn = [form, btn]
        break
      end
    end
    form_btn
  end

  def fill_form_fields(form_fields, field_name, value)
    form_fields.select { |f| f.name.match(/#{ field_name }/i) }.each do |field|
      field.value = value
    end
  end

  def find_radio_button(page_form, name = nil)
    if name.present?
      page_form.radiobuttons_with(:name => name)[0].check
    else
      page_form.radiobuttons.first
    end
  end
end