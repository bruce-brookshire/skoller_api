defmodule Skoller.Repo.Migrations.ConvertGradeScaleToBlob do
  use Ecto.Migration

  def up do
    alter table(:classes) do
      add :grade_scale_map, :map
    end
  end

  def down do
    alter table(:classes) do
      remove :grade_scale_map
    end
  end
end

