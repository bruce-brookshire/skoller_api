defmodule Skoller.Repo.Migrations.AddStudentLinks do
  @moduledoc false
  use Ecto.Migration

  def up do
    alter table(:students) do
      add :enrollment_link, :string
      add :enrolled_by, references(:students, on_delete: :nilify_all)
    end
  end

  def down do
    alter table(:students) do
      remove :enrollment_link
      remove :enrolled_by
    end
  end
end