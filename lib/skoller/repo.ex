defmodule Skoller.Repo do
  @moduledoc """
  The Skoller Repository.
  """
  use Ecto.Repo, 
    otp_app: :skoller,
    adapter: Ecto.Adapters.Postgres

  @doc """
  Dynamically loads the repository url from the
  DATABASE_URL environment variable.
  """
  def init(_, opts) do
    {:ok, Keyword.put(opts, :url, System.get_env("DATABASE_URL"))}
  end
end
