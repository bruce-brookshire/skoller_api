defmodule Skoller.Repo.Migrations.MoveProfessorsToSchool do
  use Ecto.Migration

  alias Skoller.Repo
  alias Skoller.Professors.Professor
  alias Skoller.Periods.ClassPeriod
  alias Skoller.Professors.OldProfessor

  def up do
    alter table(:professors) do
      add :school_id, references(:schools, on_delete: :delete_all)
    end

    create index(:professors, [:school_id])
    flush()
    OldProfessor
    |> Repo.all()
    |> Enum.map(&make_changeset(&1))
    |> Enum.each(&Repo.update!(&1))
    flush()
    drop constraint("professors", "professors_class_period_id_fkey")
    drop index(:professors, [:class_period_id])
    alter table(:professors) do
      remove :class_period_id
    end
  end

  defp make_changeset(prof) do
    period = Repo.get!(ClassPeriod, prof.class_period_id)
    prof = Repo.get!(Professor, prof.id)
    prof 
    |> Ecto.Changeset.change(%{school_id: period.school_id})
  end
end
