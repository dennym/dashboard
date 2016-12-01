defmodule APIs.ForecastIO do
  @units "us"

  def get(location) do
    url = "https://api.forecast.io/forecast/"
      <> api_key
      <> "/" <> location
      <> "?units=" <> @units

    HTTPoison.get!(url).body |> Poison.decode!
  end

  def forecast_for_widget(forecast) do
    %{
      temperature: "#{temp_to_english forecast["currently"]["temperature"]}º",
      summary: forecast["minutely"]["summary"]
    }
  end

  defp config, do: Application.get_env(:dashboard, :forecast_io, %{})
  defp api_key, do: config[:api_key]

  defp temp_to_english(temp), do: temp |> Float.round |> trunc
end
