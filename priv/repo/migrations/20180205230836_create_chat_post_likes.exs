defmodule Classnavapi.Repo.Migrations.CreateChatPostLikes do
  use Ecto.Migration

  def change do
    create table(:chat_post_likes) do
      add :chat_post_id, references(:chat_posts, on_delete: :delete_all)
      add :student_id, references(:students, on_delete: :nothing)

      timestamps()
    end

    create index(:chat_post_likes, [:chat_post_id])
    create index(:chat_post_likes, [:student_id])
    create unique_index(:chat_post_likes, [:student_id, :chat_post_id], name: :unique_post_like_index)
  end
end
