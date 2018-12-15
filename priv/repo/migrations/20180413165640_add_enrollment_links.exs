defmodule Skoller.Repo.Migrations.AddEnrollmentLinks do
  @moduledoc false
  use Ecto.Migration

  def change do
    alter table(:student_classes) do
      add :enrollment_link, :string
      add :enrolled_by, references(:student_classes, on_delete: :nilify_all)
    end
  end
end
