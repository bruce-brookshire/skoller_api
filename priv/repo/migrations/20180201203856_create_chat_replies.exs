defmodule Skoller.Repo.Migrations.CreateChatReplies do
  use Ecto.Migration

  def change do
    create table(:chat_replies) do
      add :reply, :string
      add :student_id, references(:students, on_delete: :nothing)
      add :chat_comment_id, references(:chat_comments, on_delete: :delete_all)

      timestamps()
    end

    create index(:chat_replies, [:student_id])
    create index(:chat_replies, [:chat_comment_id])
  end
end
