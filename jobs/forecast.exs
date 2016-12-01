use Kitto.Job.DSL

location = Application.get_env(:dashboard, :forecast_io)[:location]

job :forecast, every: {10, :minutes} do
  forecast = APIs.ForecastIO.get(location)
  |> APIs.ForecastIO.forecast_for_widget

  broadcast! :forecast, forecast
end
