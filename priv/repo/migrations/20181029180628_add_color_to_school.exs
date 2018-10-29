defmodule Skoller.Repo.Migrations.AddColorToSchool do
  use Ecto.Migration

  def change do
    alter table(:schools) do
      add :color, :string
    end
  end
end
