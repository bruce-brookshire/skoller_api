defmodule Classnavapi.Repo.Migrations.IncreaseChatLengths do
  use Ecto.Migration

  def change do
    alter table(:chat_posts) do
      modify :post, :string, size: 750
    end

    alter table(:chat_comments) do
      modify :comment, :string, size: 750
    end

    alter table(:chat_replies) do
      modify :reply, :string, size: 750
    end
  end
end
