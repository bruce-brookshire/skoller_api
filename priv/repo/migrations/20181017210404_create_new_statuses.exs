defmodule Skoller.Repo.Migrations.CreateNewStatuses do
  @moduledoc false
  use Ecto.Migration

  alias Skoller.ClassStatuses.Status
  alias Skoller.Repo
  alias Skoller.Classes.Class
  alias Skoller.ClassStatuses.Status

  import Ecto.Query

  def change do
    Repo.insert!(%Status{id: 1100, name: "Needs Setup", is_complete: false})
    Repo.insert!(%Status{id: 1200, name: "Syllabus Submitted", is_complete: false})
    Repo.insert!(%Status{id: 1300, name: "Needs Student Input", is_complete: false})
    Repo.insert!(%Status{id: 1400, name: "Class Setup", is_complete: true})
    Repo.insert!(%Status{id: 1500, name: "Class Issue", is_complete: true})

    flush()

    from(c in Class)
    |> where([c], c.class_status_id == 200)
    |> Repo.update_all(set: [class_status_id: 1100])

    from(c in Class)
    |> where([c], c.class_status_id in [300, 400, 500])
    |> Repo.update_all(set: [class_status_id: 1200])

    from(c in Class)
    |> where([c], c.class_status_id == 600)
    |> Repo.update_all(set: [class_status_id: 1300])

    from(c in Class)
    |> where([c], c.class_status_id == 700)
    |> Repo.update_all(set: [class_status_id: 1400])

    from(c in Class)
    |> where([c], c.class_status_id == 800)
    |> Repo.update_all(set: [class_status_id: 1500])

    flush()

    from(s in Status)
    |> where([s], s.id < 1000)
    |> Repo.delete_all()
  end
end
