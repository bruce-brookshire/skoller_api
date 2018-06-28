defmodule Skoller.Repo.Migrations.AddUpperEdToggle do
  use Ecto.Migration

  alias Skoller.Repo

  def up do
    rename table("schools"), :adr_city, to: :adr_locality
    rename table("schools"), :adr_state, to: :adr_region
    alter table(:schools) do
      add :is_university, :boolean, default: true, null: false
      add :adr_line_3, :string
      add :adr_country, :string
    end
    flush()
    Skoller.Schools.School
    |> Repo.all()
    |> Enum.map(&Ecto.Changeset.change(&1, %{adr_country: "us"}))
    |> Enum.each(&Repo.update!(&1))
  end

  def down do
    rename table("schools"), :adr_locality, to: :adr_city
    rename table("schools"), :adr_region, to: :adr_state
    alter table(:schools) do
      remove :is_university
      remove :adr_line_3
      remove :adr_country
    end
  end
end
