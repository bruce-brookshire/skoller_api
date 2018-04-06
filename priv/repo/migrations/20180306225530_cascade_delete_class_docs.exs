defmodule Skoller.Repo.Migrations.CascadeDeleteClassDocs do
  use Ecto.Migration

  def change do
    drop constraint("docs", "docs_class_id_fkey")
    alter table(:docs) do
      modify :class_id, references(:classes, on_delete: :delete_all)
    end
  end
end
