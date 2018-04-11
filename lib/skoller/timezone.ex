defmodule Skoller.Timezone do
  require Logger

  @get_tz_url "get-time-zone"

  def get_timezone(locality, country, region \\ nil) do
    case request(@get_tz_url, %{by: "city", country: country, region: region, city: locality}) do
      {:ok, %{"zones" => zones}} ->
        case zones |> Enum.count() do
          0 -> {:ok, nil}
          1 -> 
            zone = zones |> List.first()
            {:ok, zone["zoneName"]}
          _num -> {:ok, nil}
        end
      {:error, error} ->
        {:error, error}
    end
  end

  defp request(url, params) do
    case Timezone.get(url, [], params: params) do
      {:ok, response} ->
        {:ok, response.body}
      {:error, response} ->
        Logger.error("timezone call failed.")
        Logger.error(inspect(response))
        {:error, response}
      end
  end
end