defmodule Skoller.Repo.Migrations.CreateChatPosts do
  use Ecto.Migration

  def change do
    create table(:chat_posts) do
      add :post, :string
      add :student_id, references(:students, on_delete: :nothing)
      add :class_id, references(:classes, on_delete: :nothing)

      timestamps()
    end

    create index(:chat_posts, [:student_id])
    create index(:chat_posts, [:class_id])
  end
end
