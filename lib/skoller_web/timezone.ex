defmodule SkollerWeb.Timezone do
  require Logger

  @get_tz_url "get-time-zone"

  def get_timezone(locality, region, country) do
    
  end

  def get_timezone(zone) do
    request(@get_tz_url, %{by: "zone", zone: zone})
  end

  defp request(url, params) do
    case Timezone.get(url, [], params: params) do
      {:ok, response} ->
        response.body
      {:error, response} ->
        Logger.error("timezone call failed.")
        Logger.error(inspect(response))
      end
  end
end