defmodule Sammi do
  @moduledoc """
  Uses `HTTPoison.Base` to create a web interface with the Sammi API.
  """

  use HTTPoison.Base

  def process_url(url) do
    to_string(System.get_env("SAMMI_URL")) <> url
  end

  def process_response_body(""), do: ""
  def process_response_body(body) do
    require Logger
    Logger.info(inspect(body))
    case body |> Poison.decode() do
      {:ok, decode} -> decode
      {:error, _error} -> {:error, body}
    end
  end
end