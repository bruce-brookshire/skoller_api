defmodule Skoller.Repo.Migrations.UpdateConstraintsOnActions do
  @moduledoc false
  use Ecto.Migration

  def change do
    drop constraint("modification_actions", "modification_actions_student_class_id_fkey")
    alter table(:modification_actions) do
      modify :student_class_id, references(:student_classes, on_delete: :delete_all)
    end
  end
end
