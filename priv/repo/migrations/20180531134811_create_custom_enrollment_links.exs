defmodule Skoller.Repo.Migrations.CreateCustomEnrollmentLinks do
  use Ecto.Migration

  def change do
    create table(:custom_enrollment_links) do
      add :name, :string
      add :link, :string
      add :start, :date
      add :end, :date

      timestamps()
    end

    create unique_index(:custom_enrollment_links, [:link], name: :unique_enrollment_link_index)
  end
end
