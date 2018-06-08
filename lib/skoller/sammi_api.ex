defmodule Sammi.Api do
  require Logger

  @extract_url "/extract"
  
  def extract(path) do
    case get(@extract_url <> "/" <> path, [recv_timeout: 5 * 60 * 1000]) do
      {:ok, response} ->
        {:ok, response}
      {:error, error} ->
        {:error, error}
    end
  end

  defp get(url, params) do
    case Sammi.get(url, [], params) do
      {:ok, response} ->
        {:ok, response.body}
      {:error, response} ->
        Logger.error("sammi call failed.")
        Logger.error(inspect(response))
        {:error, response}
    end
  end
end