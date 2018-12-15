defmodule Skoller.Repo.Migrations.AddOrganizationToStudent do
  @moduledoc false
  use Ecto.Migration

  def change do
    alter table(:students) do
      add :primary_organization_id, references(:organizations, on_delete: :nilify_all)
    end
    create index(:students, [:primary_organization_id])
  end
end
