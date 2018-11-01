defmodule Skoller.Repo.Migrations.AddMainSchoolToStudent do
  use Ecto.Migration

  def change do
    alter table(:students) do
      add :primary_school_id, references(:schools, on_delete: :nothing)
    end
    create index(:students, [:primary_school_id])
  end
end
