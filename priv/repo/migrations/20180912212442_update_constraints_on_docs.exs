defmodule Skoller.Repo.Migrations.UpdateConstraintsOnDocs do
  @moduledoc false
  use Ecto.Migration

  def change do
    drop constraint("docs", "docs_user_id_fkey")
    alter table(:docs) do
      modify :user_id, references(:users, on_delete: :nilify_all)
    end
  end
end
