defmodule Skoller.Application do
  @moduledoc """
  The Application entrypoint for Skoller.
  """

  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(Skoller.Repo, []),
      # Start the endpoint when the application starts
      supervisor(SkollerWeb.Endpoint, []),
      # Start your own worker by calling:
      # Skoller.Worker.start_link(arg1, arg2, arg3)
      # worker(Skoller.Worker, [arg1, arg2, arg3]),
      worker(Skoller.AssignmentReminderJob, []),
      worker(Skoller.ClassLocksJob, []),
      worker(Skoller.ClassPeriodJob, []),
      worker(Skoller.ClassSetupJob, []),
      worker(Skoller.NoClassesJob, []),
      worker(Skoller.EmailManagerJob, []),
      worker(Skoller.ClassStartNotificationJob, [])
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
