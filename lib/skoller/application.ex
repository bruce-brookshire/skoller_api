defmodule Skoller.Application do
  @moduledoc """
  The Application entrypoint for Skoller.
  """

  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do

    # Define workers and child supervisors to be supervised
    children = [
      Skoller.Repo,
      {Oban, Application.fetch_env!(:oban, Oban)},
      SkollerWeb.Endpoint,
      {Phoenix.PubSub, [name: Skoller.PubSub, adapter: Phoenix.PubSub.PG2]},
      %{id: AirtableSyncJob, start: {Skoller.AirtableSyncJob, :start_link, []}}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Skoller.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    SkollerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
