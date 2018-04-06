defmodule Skoller.Repo.Migrations.CreateChatComments do
  use Ecto.Migration

  def change do
    create table(:chat_comments) do
      add :comment, :string
      add :student_id, references(:students, on_delete: :nothing)
      add :chat_post_id, references(:chat_posts, on_delete: :delete_all)

      timestamps()
    end

    create index(:chat_comments, [:student_id])
    create index(:chat_comments, [:chat_post_id])
  end
end
