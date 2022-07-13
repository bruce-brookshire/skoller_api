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
      %{id: AssignmentReminderJob, start: {Skoller.AssignmentReminderJob, :start_link, []}},
      %{id: ClassLocksJob, start: {Skoller.ClassLocksJob, :start_link, []}},
      %{id: ClassPeriodJob, start: {Skoller.ClassPeriodJob, :start_link, []}},
      %{id: ClassSetupJob, start: {Skoller.ClassSetupJob, :start_link, []}},
      %{id: NoClassesJob, start: {Skoller.NoClassesJob, :start_link, []}},
      %{id: EmailManagerJob, start: {Skoller.EmailManagerJob, :start_link, []}},
      %{id: AirtableSyncJob, start: {Skoller.AirtableSyncJob, :start_link, []}},
      %{id: AnalyticsJob, start: {Skoller.AnalyticsJob, :start_link, []}},
      %{id: TrialJob, start: {Skoller.TrialJob, :start_link, []}},
      %{id: StudentsCountJob, start: {Skoller.StudentsCountJob, :start_link, []}}
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
