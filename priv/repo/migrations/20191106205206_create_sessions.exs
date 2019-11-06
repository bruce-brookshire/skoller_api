defmodule Skoller.Repo.Migrations.CreateSessions do
  alias Skoller.Sessions.SessionPlatform

  use Ecto.Migration

  def up do
    create table(:session_platforms) do
      add(:type, :string)
    end

    flush()
    
    [
      %{id: 100, type: "web"},
      %{id: 200, type: "ios"},
      %{id: 300, type: "android"}
    ]
    |> Enum.map(&SessionPlatform.insert_changeset/1)
    |> Enum.each(&Skoller.Repo.insert/1)

    create table(:sessions) do
      add(:student_id, references(:students, on_delete: :delete_all))
      add(:session_platform_id, references(:session_platforms, on_delete: :nilify_all))

      timestamps()
    end
  end

  def down do
    drop(table(:sessions))
    drop(table(:session_platforms))
  end
end
