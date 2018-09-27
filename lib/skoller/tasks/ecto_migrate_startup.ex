defmodule Mix.Tasks.Ecto.Migrate.Startup do
  @moduledoc """
  Make it so timex can be used in migrations.

  Pulled from https://stackoverflow.com/questions/51272014/argument-error-on-ets-lookuptzdata-current-release-release-version-when-ru
  """
  use Mix.Task

  def run(args) do
    Mix.shell.info("Starting apps required for ecto.migrate...")
    Application.ensure_all_started(:timex)
  end
end