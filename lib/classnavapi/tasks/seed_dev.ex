defmodule Mix.Tasks.Seed.Dev do
  use Mix.Task
  import Mix.Ecto

  alias Classnavapi.Repo

  def run(_) do
    ensure_started(Repo, [])
    Repo.insert!(%Classnavapi.User{email: "tyler@fortyau.com", password: "test"})
  end
end