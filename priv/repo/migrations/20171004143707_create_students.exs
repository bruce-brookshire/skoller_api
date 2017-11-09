defmodule Classnavapi.Repo.Migrations.CreateStudents do
  use Ecto.Migration

  def change do
    create table(:students) do
      add :name_first, :string
      add :name_last, :string
      add :major, :string
      add :phone, :string
      add :birthday, :date
      add :gender, :string
      add :school_id, references(:schools)

      timestamps()
    end

    create index(:students, [:school_id])
  end
end
