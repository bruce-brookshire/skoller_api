defmodule Classnavapi.Repo.Migrations.CreateSchools do
  use Ecto.Migration

  def change do
    create table(:schools) do
      add :name, :string
      add :adr_line_1, :string
      add :adr_line_2, :string
      add :adr_city, :string
      add :adr_state, :string
      add :adr_zip, :string
      add :timezone, :string
      add :email_domain, :string
      add :email_domain_prof, :string
      add :is_active, :boolean, default: false, null: false

      timestamps()
    end

  end
end
