defmodule APIs.Jira do
  def issues(filter) do
    jql = URI.encode "filter=" <> to_string(filter) <> "+order+by+priority+DESC,updated+ASC"
    url = URI.parse url <> "/rest/api/2/search?maxResults=25&jql=" <> jql
    HTTPoison.get!(url, authentication).body
    |> Poison.decode!
  end

  def count(issues) do
    issues["total"]
  end

  def issue_for_dashboard(issue) do
    %{
      id: issue["key"],
      summary: issue["fields"]["summary"],
      priority: issue["fields"]["priority"]
    }
  end

  defp jira_config, do: Application.get_env(:dashboard, :jira, %{})
  defp auth, do: jira_config[:auth]
  defp url, do: jira_config[:url]

  defp authentication, do: ["Authorization": "Basic " <> auth]
end
