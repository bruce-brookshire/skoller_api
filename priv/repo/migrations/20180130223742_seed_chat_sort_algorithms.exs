defmodule Skoller.Repo.Migrations.SeedChatSortAlgorithms do
  use Ecto.Migration

  def up do
    Skoller.Repo.insert!(%Skoller.Chat.Algorithm{id: 100, name: "Hot"})
    Skoller.Repo.insert!(%Skoller.Chat.Algorithm{id: 200, name: "Most Recent"})
    Skoller.Repo.insert!(%Skoller.Chat.Algorithm{id: 300, name: "Top from the past 24 hours"})
    Skoller.Repo.insert!(%Skoller.Chat.Algorithm{id: 400, name: "Top from the past week"})
    Skoller.Repo.insert!(%Skoller.Chat.Algorithm{id: 500, name: "Top from the semester"})
  end

  def down do
    Skoller.Repo.delete!(%Skoller.Chat.Algorithm{id: 100, name: "Hot"})
    Skoller.Repo.delete!(%Skoller.Chat.Algorithm{id: 200, name: "Most Recent"})
    Skoller.Repo.delete!(%Skoller.Chat.Algorithm{id: 300, name: "Top from the past 24 hours"})
    Skoller.Repo.delete!(%Skoller.Chat.Algorithm{id: 400, name: "Top from the past week"})
    Skoller.Repo.delete!(%Skoller.Chat.Algorithm{id: 500, name: "Top from the semester"})
  end
end
