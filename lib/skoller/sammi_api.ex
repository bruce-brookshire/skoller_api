defmodule Sammi.Api do
  @moduledoc """
  The Sammi API
  """
  require Logger

  @extract_url "/extract"
  @status_url "/"
  
  @doc """
  Extracts a syllabus at the `path`.

  ## Returns
  `{:ok, Map}` or `{:error, reason}`
  """
  def extract(path) do
    case get(@extract_url <> "/" <> path, [recv_timeout: 5 * 60 * 1000]) do
      {:ok, response} ->
        {:ok, response}
      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Checks the status of Sammi

  ## Returns
  `:ok` or `:error`
  """
  def status() do
    case get(@status_url, []) do
      {:ok, _response} ->
        :ok
      {:error, response} ->
        Logger.error("sammi status failed.")
        Logger.error(inspect(response))
        :error
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