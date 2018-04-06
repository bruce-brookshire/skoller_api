defmodule Skoller.Repo.Migrations.CreateEmailDomains do
  use Ecto.Migration

  def change do
    create table(:email_domains) do
      add :email_domain, :string
      add :is_professor_only, :boolean
      add :school_id, references(:schools, on_delete: :nothing)

      timestamps()
    end

    create index(:email_domains, [:school_id])
  end
end
