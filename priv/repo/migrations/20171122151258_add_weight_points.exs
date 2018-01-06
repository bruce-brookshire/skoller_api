defmodule Classnavapi.Repo.Migrations.AddWeightPoints do
  use Ecto.Migration

  def change do
    alter table(:classes) do
      add :is_points, :boolean, default: false, null: false
    end
  end
end
