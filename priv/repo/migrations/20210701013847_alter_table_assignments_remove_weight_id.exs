defmodule Skoller.Repo.Migrations.AlterTableAssignmentsRemoveWeightId do
  use Ecto.Migration

  def change do
    alter table(:assignments) do
      remove :weight_id
    end
  end
end
