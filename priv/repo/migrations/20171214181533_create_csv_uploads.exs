defmodule Classnavapi.Repo.Migrations.CreateCsvUploads do
  use Ecto.Migration

  def change do
    create table(:csv_uploads) do
      add :name, :string

      timestamps()
    end

    create unique_index(:csv_uploads, [:name], name: :csv_unique_index)
  end
end
