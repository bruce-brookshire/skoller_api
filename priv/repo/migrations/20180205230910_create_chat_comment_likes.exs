defmodule Classnavapi.Repo.Migrations.CreateChatCommentLikes do
  use Ecto.Migration

  def change do
    create table(:chat_comment_likes) do
      add :chat_comment_id, references(:chat_comments, on_delete: :delete_all)
      add :student_id, references(:students, on_delete: :nothing)

      timestamps()
    end

    create index(:chat_comment_likes, [:chat_comment_id])
    create index(:chat_comment_likes, [:student_id])
    create unique_index(:chat_comment_likes, [:student_id, :chat_comment_id], name: :unique_comment_like_index)
  end
end
