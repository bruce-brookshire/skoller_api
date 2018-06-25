defmodule Skoller.Repo.Migrations.AddUniqueSchoolIndex do
  use Ecto.Migration

  def change do
    create unique_index(:schools, [:name, :adr_locality, :adr_region, :adr_country], name: :unique_school_index)
  end
end
