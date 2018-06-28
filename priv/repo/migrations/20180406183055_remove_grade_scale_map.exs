defmodule Skoller.Repo.Migrations.RemoveGradeScaleMap do
  use Ecto.Migration

  def change do
    alter table(:classes) do
      remove :grade_scale
    end
    flush()
    rename table("classes"), :grade_scale_map, to: :grade_scale
  end
end
