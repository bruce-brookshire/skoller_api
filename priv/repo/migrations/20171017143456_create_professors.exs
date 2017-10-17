defmodule Classnavapi.Repo.Migrations.CreateProfessors do
  use Ecto.Migration

  def change do
    create table(:professors) do
      add :name_first, :string
      add :name_last, :string
      add :email, :string
      add :phone, :string
      add :office_location, :string
      add :office_availability, :string
      add :class_period_id, references(:class_periods, on_delete: :nothing)

      timestamps()
    end

    create index(:professors, [:class_period_id])
  end
end
