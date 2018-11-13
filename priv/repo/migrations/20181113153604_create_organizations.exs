defmodule Skoller.Repo.Migrations.CreateOrganizations do
  use Ecto.Migration

  def change do
    create table(:organizations) do
      add :name, :string
      add :custom_signup_link_id, references(:custom_signup_links, on_delete: :nothing)

      timestamps()
    end

    create index(:organizations, [:custom_signup_link_id])
  end
end
