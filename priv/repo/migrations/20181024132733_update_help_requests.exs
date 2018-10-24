defmodule Skoller.Repo.Migrations.UpdateHelpRequests do
  use Ecto.Migration

  alias Skoller.Repo
  alias Skoller.HelpRequests.Type

  def change do
    Repo.get(Type, 200) |> delete()
    Repo.get(Type, 400) |> delete()
    Repo.insert!(%Type{id: 500, name: "No weights or assignments"})

    alter table(:class_help_requests) do
      remove :is_completed
    end
  end

  defp delete(nil), do: nil
  defp delete(thing), do: Repo.delete(thing)
end
