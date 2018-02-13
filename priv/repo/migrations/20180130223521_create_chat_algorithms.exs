defmodule Classnavapi.Repo.Migrations.CreateChatAlgorithms do
  use Ecto.Migration

  def change do
    create table(:chat_algorithms) do
      add :name, :string

      timestamps()
    end

  end
end
