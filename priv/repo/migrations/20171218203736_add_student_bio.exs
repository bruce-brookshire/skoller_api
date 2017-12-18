defmodule Classnavapi.Repo.Migrations.AddStudentBio do
  use Ecto.Migration

  def change do
    alter table(:students) do
      add :bio, :string
      add :organization, :string
    end
  end
end
