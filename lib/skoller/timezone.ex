defmodule Skoller.Timezone do
  @moduledoc """
  Timezone API module.
  """
  require Logger

  @get_tz_url "get-time-zone"
  @state_timezones %{
    "CA" => "America/Los_Angeles",
    "NV" => "America/Los_Angeles",
    "OR" => "America/Los_Angeles",
    "WA" => "America/Los_Angeles",
    "AZ" => "America/Denver",
    "CO" => "America/Denver",
    "ID" => "America/Denver",
    "MT" => "America/Denver",
    "NM" => "America/Denver",
    "UT" => "America/Denver",
    "WY" => "America/Denver",
    "HI" => "Pacific/Honolulu",
    "CT" => "America/New_York",
    "DE" => "America/New_York",
    "DC" => "America/New_York",
    "FL" => "America/New_York",
    "GA" => "America/New_York",
    "IN" => "America/New_York",
    "ME" => "America/New_York",
    "MD" => "America/New_York",
    "MA" => "America/New_York",
    "MI" => "America/New_York",
    "NH" => "America/New_York",
    "NJ" => "America/New_York",
    "NY" => "America/New_York",
    "NC" => "America/New_York",
    "OH" => "America/New_York",
    "PA" => "America/New_York",
    "RI" => "America/New_York",
    "SC" => "America/New_York",
    "VT" => "America/New_York",
    "VA" => "America/New_York",
    "WV" => "America/New_York",
    "AL" => "America/Chicago",
    "AR" => "America/Chicago",
    "IL" => "America/Chicago",
    "IA" => "America/Chicago",
    "KS" => "America/Chicago",
    "KY" => "America/Chicago",
    "LA" => "America/Chicago",
    "MN" => "America/Chicago",
    "MS" => "America/Chicago",
    "MO" => "America/Chicago",
    "NE" => "America/Chicago",
    "ND" => "America/Chicago",
    "OK" => "America/Chicago",
    "SD" => "America/Chicago",
    "TN" => "America/Chicago",
    "TX" => "America/Chicago",
    "WI" => "America/Chicago",
    "AK" => "America/Anchorage"
  }

  @doc """
  Gets the timezone for a given `locality`, `country`, and `region`.

  Locality is the City, Region is the State. Region is not required if the country is not the US.

  ## Returns
   * `{:ok, String}` if one timezone is found. The timezone name is the long form name (i.e. "America/Chicago")
   * `{:ok, nil}` if no timezone is found, or multiple are found.
   * `{:error, error}` if there is an error.
  """
  def get_timezone(locality, country, region \\ nil) do
    case request(@get_tz_url, %{by: "city", country: country, region: region, city: locality})
         |> IO.inspect() do
      {:ok, %{"zones" => zones}} ->
        case zones |> Enum.count() do
          0 ->
            {:ok, @state_timezones[region || ""]}

          1 ->
            zone = zones |> List.first()
            {:ok, zone["zoneName"]}

          _num ->
            zone = zones |> List.first()

            case zones |> Enum.all?(&(&1["zoneName"] == zone["zoneName"])) do
              true ->
                {:ok, zone["zoneName"]}

              false ->
                {:ok, @state_timezones[region || ""]}
            end
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
        Logger.debug("Received: ")
        Logger.debug(inspect(response.body))
        {:ok, response.body}

      {:error, response} ->
        Logger.error("timezone call failed.")
        Logger.error(inspect(response))
        {:error, response}
    end
  end
end
