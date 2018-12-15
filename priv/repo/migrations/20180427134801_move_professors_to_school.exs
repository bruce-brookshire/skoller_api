defmodule Skoller.Repo.Migrations.MoveProfessorsToSchool do
  @moduledoc false
  use Ecto.Migration

  def up do
    alter table(:professors) do
      add :school_id, references(:schools, on_delete: :delete_all)
    end

    create index(:professors, [:school_id])
    drop constraint("professors", "professors_class_period_id_fkey")
    drop index(:professors, [:class_period_id])
    alter table(:professors) do
      remove :class_period_id
    end
  end
end
