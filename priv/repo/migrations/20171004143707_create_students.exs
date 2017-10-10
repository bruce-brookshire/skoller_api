defmodule Classnavapi.Repo.Migrations.CreateStudents do
  use Ecto.Migration

  def change do
    create table(:students) do
      add :name_first, :string
      add :name_last, :string
      add :phone, :string
      add :birthday, :date
      add :gender, :string

      timestamps()
    end

  end
end
