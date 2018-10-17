defmodule Skoller.Repo.Migrations.CreateNewStatuses do
  use Ecto.Migration

  def change do
    Skoller.Repo.insert!(%Skoller.ClassStatuses.Status{id: 1100, name: "Needs Setup", is_complete: false})
    Skoller.Repo.insert!(%Skoller.ClassStatuses.Status{id: 1200, name: "Syllabus Submitted", is_complete: false})
    Skoller.Repo.insert!(%Skoller.ClassStatuses.Status{id: 1300, name: "Class Setup", is_complete: true})
    Skoller.Repo.insert!(%Skoller.ClassStatuses.Status{id: 1400, name: "Class Issue", is_complete: true})
    Skoller.Repo.insert!(%Skoller.ClassStatuses.Status{id: 1500, name: "Needs Student Input", is_complete: true})
  end
end
