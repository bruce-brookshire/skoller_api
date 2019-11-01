defmodule Skoller.Repo.Migrations.AtomicChangeRequestElements do
  alias Skoller.ChangeRequests.ChangeRequestDeprecated
  alias Skoller.ChangeRequests.ChangeRequestMember
  alias Skoller.ChangeRequests.ChangeRequest
  alias Skoller.Repo

  import Ecto.Query

  use Ecto.Migration

  def up do
    create table(:class_change_request_members) do
      add(:class_change_request_id, references(:class_change_requests, on_delete: :delete_all))
      add(:name, :string)
      add(:value, :string)
      add(:is_completed, :boolean, default: false)

      timestamps()
    end

    create(index(:class_change_request_members, [:class_change_request_id]))

    flush()

    Repo.all(ChangeRequestDeprecated)
    |> Enum.flat_map(&distill_data/1)
    |> Enum.filter(& &1.valid?)
    |> IO.inspect
    |> Enum.each(&Repo.insert/1)

    alter table(:class_change_requests) do
      remove(:data)
      remove(:is_completed)
    end
  end

  def down do
    alter table(:class_change_requests) do
      add(:data, {:map, :string})
      add(:is_completed, :boolean, default: false)
    end

    flush()

    from(c in ChangeRequestDeprecated)
    |> preload([c], [:class_change_request_members])
    |> Repo.all()
    |> Enum.map(&create_data/1)
    |> Enum.each(&Repo.update/1)

    drop(table(:class_change_request_members))
  end

  defp distill_data(%{data: data, id: id, is_completed: completion}) when not is_nil(data),
    do: Enum.map(data, &distill_data(&1, id, completion))

  defp distill_data(%{id: id}) do
    IO.puts("Change Request #{id} has no data")
    []
  end

  defp distill_data({k, v}, change_request_id, request_completed),
    do:
      %ChangeRequestMember{}
      |> ChangeRequestMember.changeset(%{
        name: k,
        value: v,
        is_completed: request_completed,
        class_change_request_id: change_request_id
      })

  defp create_data(%ChangeRequestDeprecated{class_change_request_members: members} = request) do
    data = Enum.map(members, &create_data/1) |> Map.new()

    request |> ChangeRequestDeprecated.changeset(%{data: data})
  end

  defp create_data(%ChangeRequestMember{name: name, value: value}), do: {name, value}
end
