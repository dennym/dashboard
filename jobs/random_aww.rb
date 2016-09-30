require 'net/http'
require 'json'

placeholder = '/assets/images/nyantocat.gif'

SCHEDULER.every '60s', first_in: 0 do |job|
  uri = URI.parse 'https://www.reddit.com/r/aww.json'
  http = Net::HTTP.new uri.host, uri.port
  http.use_ssl = uri.scheme == 'https'
  request =  Net::HTTP::Get.new uri.to_s
  request.add_field 'Accept', 'application/json'
  json = JSON.parse(http.request(request).body)

  if json['data']['children'].count <= 0
    send_event('aww', image: placeholder)
  else
    urls = json['data']['children'].map{|child| child['data']['url'] }

    # Ensure we're linking directly to an image, not a gallery etc.
    valid_urls = urls.select{|url| url.downcase.end_with?('png', 'gif', 'jpg', 'jpeg')}
    send_event('aww', image: "background-image:url(#{valid_urls.sample(1).first})")
  end
end
