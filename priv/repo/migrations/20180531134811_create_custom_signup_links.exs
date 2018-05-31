defmodule Skoller.Repo.Migrations.CreateCustomSignupLinks do
  use Ecto.Migration

  def change do
    create table(:custom_signup_links) do
      add :name, :string
      add :link, :string
      add :start, :date
      add :end, :date

      timestamps()
    end

    create unique_index(:custom_signup_links, [:link], name: :unique_signup_link_index)
  end
end
