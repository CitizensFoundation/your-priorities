class RemoteLinkRenderer < WillPaginate::ViewHelpers::LinkRenderer
 private

  def link(text, target, attributes = {})
    if target.is_a? Fixnum
      attributes[:rel] = rel_value(target)
      target = "/users/endorsements?page=#{target}"
    end
    attributes[:href] = target
    attributes['data-disable-with'] = ""
    attributes['data-loader-name'] = "circle"
    attributes['data-remote'] = 'true'
    tag(:a, text, attributes)
  end
end