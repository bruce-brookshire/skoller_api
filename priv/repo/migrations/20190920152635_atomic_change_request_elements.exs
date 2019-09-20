defmodule Skoller.Repo.Migrations.AtomicChangeRequestElements do
  alias Skoller.Repo
  alias Skoller.ChangeRequests.ChangeRequest
  alias Skoller.ChangeRequests.ChangeRequest.ChangeRequestMember

  import Ecto.Query

  use Ecto.Migration

  def change do
    create table(:class_change_request_members) do
      add(:class_change_request_id, references(:class_change_requests, on_delete: :delete_all))
      add(:name, :string)
      add(:value, :string)
      add(:is_completed, :boolean, default: false)

      timestamps()
    end

    flush()

    Repo.all(ChangeRequest)
    |> Enum.map(&ChangeRequestMember.changeset(%ChangeRequestMember{}, &1.data))
    |> Enum.each(&Repo.insert/1)

    flush()

    alter table(:class_change_requests) do
      remove(:data)
    end
  end
end
