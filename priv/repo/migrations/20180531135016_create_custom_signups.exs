defmodule Skoller.Repo.Migrations.CreateCustomEnrollments do
  use Ecto.Migration

  def change do
    create table(:custom_signups) do
      add :custom_signup_link_id, references(:custom_signup_links, on_delete: :nothing)
      add :student_id, references(:students, on_delete: :nothing)

      timestamps()
    end

    create index(:custom_signups, [:custom_signup_link_id])
    create index(:custom_signups, [:student_id])
    create unique_index(:custom_signups, [:custom_signup_link_id, :student_id], name: :unique_link_usage_index)
  end
end
