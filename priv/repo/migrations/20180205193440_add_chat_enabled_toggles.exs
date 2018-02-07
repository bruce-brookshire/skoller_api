defmodule Classnavapi.Repo.Migrations.AddChatEnabledToggles do
  use Ecto.Migration

  def change do
    alter table(:classes) do
      add :is_chat_enabled, :boolean, default: true, null: false
    end

    alter table(:schools) do
      add :is_chat_enabled, :boolean, default: true, null: false
    end
  end
end
