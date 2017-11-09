defmodule ClassnavapiWeb.Class.StatusView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.Class.StatusView

  def render("index.json", %{statuses: statuses}) do
    render_many(statuses, StatusView, "status.json")
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
