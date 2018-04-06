defmodule SkollerWeb.Class.StatusView do
  use SkollerWeb, :view

  alias SkollerWeb.Class.StatusView
  alias Skoller.Schools.School
  alias Skoller.Repo

  def render("index.json", %{statuses: statuses}) do
    count = Repo.all(School)
    |> Enum.count()
    %{
      schools: count,
      statuses: render_many(statuses, StatusView, "status.json")
    }
  end

  def render("show.json", %{status: status}) do
    render_one(status, StatusView, "status.json")
  end

  def render("status.json", %{status: %{classes: classes} = status}) do
    %{
      id: status.id,
      name: status.name,
      classes: classes
    }
  end

  def render("status.json", %{status: status}) do
    %{
      id: status.id,
      name: status.name
    }
  end
end
