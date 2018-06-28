defmodule Skoller.Repo.Migrations.CreateChatReplyLikes do
  use Ecto.Migration

  def change do
    create table(:chat_reply_likes) do
      add :chat_reply_id, references(:chat_replies, on_delete: :delete_all)
      add :student_id, references(:students, on_delete: :nothing)

      timestamps()
    end

    create index(:chat_reply_likes, [:chat_reply_id])
    create index(:chat_reply_likes, [:student_id])
    create unique_index(:chat_reply_likes, [:student_id, :chat_reply_id], name: :unique_reply_like_index)
  end
end
