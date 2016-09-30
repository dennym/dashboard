require 'net/http'
require 'json'
require 'open-uri'


VICTOROPS_CONFIG = {
  api_id: ENV['VICTOROPS_ID'],
  api_key: ENV['VICTOROPS_KEY']
}

def get_incidents
  uri = URI.parse 'https://api.victorops.com/api-public/v1/incidents'
  http = Net::HTTP.new uri.host, uri.port
  http.use_ssl = uri.scheme == 'https'
  request = Net::HTTP::Get.new uri.request_uri
  request.add_field 'Accept', 'application/json'
  request.add_field 'X-VO-Api-Id', VICTOROPS_CONFIG[:api_id]
  request.add_field 'X-VO-Api-Key', VICTOROPS_CONFIG[:api_key]

  JSON.parse(http.request(request).body)['incidents']
end

SCHEDULER.every '5m', first_in: 0 do
  incidents = get_incidents.reject do |incident|
    incident['currentPhase'] == 'RESOLVED'
  end.map do |incident|
    {
      label: "[#{incident['currentPhase']}] #{incident['entityDisplayName']}",
      phase: incident['currentPhase']
    }
  end

  send_event('victorops-incidents-count', current: incidents.count)
  send_event('victorops-incidents', items: incidents)
end
