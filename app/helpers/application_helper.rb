module ApplicationHelper
  
  # stylesheet_link_tag(arg)
  def js_for_block(*args)
    block_content(args,"js")
  end

  def stylesheet_for_block(*args)
    block_content(args,"css")
  end

  def block_content(args,css_or_js)
    args.each do |arg|
      tag = (css_or_js == "js" ? javascript_include_tag(arg) : stylesheet_link_tag(arg))
      @asset_names = @asset_names.nil? ? [tag] : @asset_names.push(tag)
    end
    content_for :head do
      (@asset_names.join("\n")).html_safe
    end
  end
end
