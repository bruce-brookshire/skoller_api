defmodule Skoller.Timezone do
  @moduledoc """
  Timezone API module.
  """
  require Logger

  @get_tz_url "get-time-zone"

  @doc """
  Gets the timezone for a given `locality`, `country`, and `region`.

  Locality is the City, Region is the State. Region is not required if the country is not the US.

  ## Returns
   * `{:ok, String}` if one timezone is found. The timezone name is the long form name (i.e. "America/Chicago")
   * `{:ok, nil}` if no timezone is found, or multiple are found.
   * `{:error, error}` if there is an error.
  """
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

  # This sends the request and logs errors/returns responses.
  defp request(url, params) do
    Logger.info("Calling Time Zone API with params: ")
    Logger.info(inspect(params))
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