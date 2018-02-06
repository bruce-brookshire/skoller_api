defmodule Classnavapi.Repo.Migrations.CreateChatPostStars do
  use Ecto.Migration

  def change do
    create table(:chat_post_stars) do
      add :chat_post_id, references(:chat_posts, on_delete: :delete_all)
      add :student_id, references(:students, on_delete: :nothing)

      timestamps()
    end

    create index(:chat_post_stars, [:chat_post_id])
    create index(:chat_post_stars, [:student_id])
    create unique_index(:chat_post_stars, [:student_id, :chat_post_id], name: :unique_post_star_index)
  end
end
