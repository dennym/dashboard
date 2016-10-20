require 'net/http'
require 'json'
require 'open-uri'

VICTOROPS_CONFIG = {
  api_id: ENV['VICTOROPS_ID'],
  api_key: ENV['VICTOROPS_KEY'],
  org: ENV['VICTOROPS_ORG'],
  team: ENV['VICTOROPS_TEAM'],
  username: ENV['VICTOROPS_USERNAME'],
  password: ENV['VICTOROPS_PASSWORD']
}

def api_request(path)
  uri = URI.parse "https://api.victorops.com/api-public/v1#{path}"
  http = Net::HTTP.new uri.host, uri.port
  http.use_ssl = uri.scheme == 'https'
  request = Net::HTTP::Get.new uri.to_s
  request.add_field 'Accept', 'application/json'
  request.add_field 'X-VO-Api-Id', VICTOROPS_CONFIG[:api_id]
  request.add_field 'X-VO-Api-Key', VICTOROPS_CONFIG[:api_key]
  JSON.parse(http.request(request).body)
end

def private_api_request(path)
  uri = URI.parse "https://portal.victorops.com/api/v1/org/#{VICTOROPS_CONFIG[:org]}#{path}"
  http = Net::HTTP.new uri.host, uri.port
  http.use_ssl = uri.scheme == 'https'
  request = Net::HTTP::Get.new uri.to_s
  request.add_field 'Accept', 'application/json'
  request.basic_auth VICTOROPS_CONFIG[:username], VICTOROPS_CONFIG[:password]
  JSON.parse http.request(request).body
end

def incidents
  api_request('/incidents')['incidents']
end

def on_call(team)
  schedule = api_request("/team/#{team}/oncall/schedule?daysForward=0")
  on_call = schedule['schedule'].first['onCall']
  schedule['overrides'].each do |override|
    on_call = override['overrideOnCall'] if override['origOnCall'] == on_call
  end
  user = private_api_request "/users/#{on_call}"
  "#{user['firstName']} #{user['lastName']}"
end

SCHEDULER.every '2m', first_in: 0, allow_overlapping: false do
  open_incidents = incidents
    .reject { |incident| incident['currentPhase'] == 'RESOLVED' }
    .map do |incident|
      label = if incident['entityDisplayName'].empty?
        incident['entityId']
      else
        incident['entityDisplayName']
      end
      {
        label: label.gsub('&gt;', '>'),
        phase: incident['currentPhase']
      }
    end

  send_event('victorops-incidents-count', current: open_incidents.count)
  send_event('victorops-incidents', items: open_incidents)
end

SCHEDULER.every '30m', first_in: 0, allow_overlapping: false do
  send_event 'victorops-oncall', text: on_call(VICTOROPS_CONFIG['team'])
end
