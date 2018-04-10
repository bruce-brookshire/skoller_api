defmodule Skoller.Repo.Migrations.CreateChatCommentStars do
  use Ecto.Migration

  def change do
    create table(:chat_comment_stars) do
      add :chat_comment_id, references(:chat_comments, on_delete: :delete_all)
      add :student_id, references(:students, on_delete: :nothing)

      timestamps()
    end

    create index(:chat_comment_stars, [:chat_comment_id])
    create index(:chat_comment_stars, [:student_id])
    create unique_index(:chat_comment_stars, [:student_id, :chat_comment_id], name: :unique_comment_star_index)
  end
end
