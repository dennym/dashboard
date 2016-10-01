require 'net/http'
require 'json'
require 'open-uri'

VICTOROPS_CONFIG = {
  api_id: ENV['VICTOROPS_ID'],
  api_key: ENV['VICTOROPS_KEY'],
  org: ENV['VICTOROPS_ORG'],
  username: ENV['VICTOROPS_USERNAME'],
  password: ENV['VICTOROPS_PASSWORD']
}

def get_from_api(path)
  uri = URI.parse "https://api.victorops.com/api-public/v1#{path}"
  http = Net::HTTP.new uri.host, uri.port
  http.use_ssl = uri.scheme == 'https'
  request = Net::HTTP::Get.new uri.to_s
  request.add_field 'Accept', 'application/json'
  request.add_field 'X-VO-Api-Id', VICTOROPS_CONFIG[:api_id]
  request.add_field 'X-VO-Api-Key', VICTOROPS_CONFIG[:api_key]
  JSON.parse(http.request(request).body)
end

def get_from_private_api(path)
  uri = URI.parse "https://portal.victorops.com/api/v1/org/#{VICTOROPS_CONFIG[:org]}#{path}"
  http = Net::HTTP.new uri.host, uri.port
  http.use_ssl = uri.scheme == 'https'
  request = Net::HTTP::Get.new uri.to_s
  request.add_field 'Accept', 'application/json'
  request.basic_auth VICTOROPS_CONFIG[:username], VICTOROPS_CONFIG[:password]
  JSON.parse http.request(request).body
end

def get_incidents
  get_from_api('/incidents')['incidents']
end

def get_oncall(team)
  schedule = get_from_api("/team/#{team}/oncall/schedule?daysForward=0")
  on_call = schedule['schedule'].first['onCall']
  schedule['overrides'].each do |override|
    if override['origOnCall'] == on_call
      on_call = override['overrideOnCall']
    end
  end
  user = get_from_private_api "/users/#{on_call}"
  "#{user['firstName']} #{user['lastName']}"
end

SCHEDULER.every '2m', first_in: 0 do
  incidents = get_incidents
    .reject { |incident| incident['currentPhase'] == 'RESOLVED' }
    .map do |incident|
      display_name = incident['entityDisplayName'].gsub('&gt;', '>')
      {
        label: "[#{incident['currentPhase'].downcase}] #{display_name}",
        phase: incident['currentPhase']
      }
    end

  send_event('victorops-incidents-count', current: incidents.count)
  send_event('victorops-incidents', items: incidents)
end

SCHEDULER.every '30m', first_in: 0 do
  on_call = get_oncall 'support-team'
  send_event 'victorops-oncall', text: on_call
end
