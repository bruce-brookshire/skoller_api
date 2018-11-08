defmodule Skoller.Repo.Migrations.CreateSchoolEmailDomains do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:school_email_domains) do
      add :email_domain, :string
      add :school_id, references(:schools, on_delete: :nothing)

      timestamps()
    end

    create index(:school_email_domains, [:school_id])
  end
end
