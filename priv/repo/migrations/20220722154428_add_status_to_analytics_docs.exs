defmodule Skoller.Repo.Migrations.AddStatusToAnalyticsDocs do
  use Ecto.Migration

  def change do
    alter table(:analytics_documents) do
      add :status, :string
    end
  end
end
