require 'net/http'
require 'json'
require 'time'
require 'open-uri'
require 'cgi'

yaml_file = "./conf/jira_issuecount.yaml"
if File.exist?(yaml_file)
  JIRA_OPENISSUES_CONFIG = YAML.load(File.new(yaml_file, "r").read)
else
  JIRA_OPENISSUES_CONFIG = {
    jira_url: ENV['JIRA_URL'],
    username:  ENV['JIRA_USERNAME'],
    password: ENV['JIRA_PASSWORD'],
    issuecount_mapping: {
      'service-desk-issues' => "filter=#{ENV['JIRA_FILTER']}"
    }
  }
end

def get_number_of_issues(url, username, password, jql_string)
  jql = CGI.escape(jql_string)
  uri = URI.parse("#{url}/rest/api/2/search?jql=#{jql}")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == 'https'
  request = Net::HTTP::Get.new(uri.request_uri)
  if !username.nil? && !username.empty?
    request.basic_auth(username, password)
  end
  JSON.parse(http.request(request).body)["total"]
end

JIRA_OPENISSUES_CONFIG[:issuecount_mapping].each do |mapping_name, filter|
  SCHEDULER.every '5m', first_in: 0, allow_overlapping: false do
    total = get_number_of_issues(JIRA_OPENISSUES_CONFIG[:jira_url], JIRA_OPENISSUES_CONFIG[:username], JIRA_OPENISSUES_CONFIG[:password], filter)
    send_event(mapping_name, {current: total})
  end
end
