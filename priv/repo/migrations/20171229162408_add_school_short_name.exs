defmodule Classnavapi.Repo.Migrations.AddSchoolShortName do
  use Ecto.Migration

  def change do
    alter table(:schools) do
      add :short_name, :string
    end

    create unique_index(:schools, [:short_name])
  end
end
