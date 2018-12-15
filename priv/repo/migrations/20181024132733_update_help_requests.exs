defmodule Skoller.Repo.Migrations.UpdateHelpRequests do
  @moduledoc false
  use Ecto.Migration

  alias Skoller.Repo
  alias Skoller.HelpRequests.Type
  alias Skoller.HelpRequests.HelpRequest

  import Ecto.Query

  def change do
    from(h in HelpRequest)
    |> where([h], h.class_help_type_id in [200, 400])
    |> Repo.delete_all()

    Repo.get(Type, 200) |> delete()
    Repo.get(Type, 400) |> delete()
    Repo.insert!(%Type{id: 500, name: "No weights or assignments"})

    alter table(:class_help_requests) do
      remove :is_completed
    end

    Repo.get(Skoller.Locks.Section, 300) |> delete()
    Repo.get(Skoller.ClassStatuses.Status, 200) |> delete()
    Repo.get(Skoller.ClassStatuses.Status, 300) |> delete()
    Repo.get(Skoller.ClassStatuses.Status, 400) |> delete()
    Repo.get(Skoller.ClassStatuses.Status, 500) |> delete()
    Repo.get(Skoller.ClassStatuses.Status, 600) |> delete()
    Repo.get(Skoller.ClassStatuses.Status, 700) |> delete()
    Repo.get(Skoller.ClassStatuses.Status, 800) |> delete()
  end

  defp delete(nil), do: nil
  defp delete(thing), do: Repo.delete(thing)
end
