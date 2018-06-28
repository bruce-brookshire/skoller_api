defmodule Skoller.Repo.Migrations.MakeInboxReadable do
  use Ecto.Migration

  def change do
    alter table(:chat_post_stars) do
      add :is_read, :boolean, default: false, null: false
    end

    alter table(:chat_comment_stars) do
      add :is_read, :boolean, default: false, null: false
    end
  end
end
