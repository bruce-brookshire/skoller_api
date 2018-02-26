defmodule Classnavapi.Repo.Migrations.SeedChatSortAlgorithms do
  use Ecto.Migration

  def up do
    Classnavapi.Repo.insert!(%Classnavapi.Chat.Algorithm{id: 100, name: "Hot"})
    Classnavapi.Repo.insert!(%Classnavapi.Chat.Algorithm{id: 200, name: "Most Recent"})
    Classnavapi.Repo.insert!(%Classnavapi.Chat.Algorithm{id: 300, name: "Top from the past 24 hours"})
    Classnavapi.Repo.insert!(%Classnavapi.Chat.Algorithm{id: 400, name: "Top from the past week"})
    Classnavapi.Repo.insert!(%Classnavapi.Chat.Algorithm{id: 500, name: "Top from the semester"})
  end

  def down do
    Classnavapi.Repo.delete!(%Classnavapi.Chat.Algorithm{id: 100, name: "Hot"})
    Classnavapi.Repo.delete!(%Classnavapi.Chat.Algorithm{id: 200, name: "Most Recent"})
    Classnavapi.Repo.delete!(%Classnavapi.Chat.Algorithm{id: 300, name: "Top from the past 24 hours"})
    Classnavapi.Repo.delete!(%Classnavapi.Chat.Algorithm{id: 400, name: "Top from the past week"})
    Classnavapi.Repo.delete!(%Classnavapi.Chat.Algorithm{id: 500, name: "Top from the semester"})
  end
end
