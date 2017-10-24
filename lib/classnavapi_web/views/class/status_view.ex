defmodule ClassnavapiWeb.Class.StatusView do
    use ClassnavapiWeb, :view
  
    alias ClassnavapiWeb.Class.StatusView
  
    def render("index.json", %{statuses: statuses}) do
      render_many(statuses, StatusView, "status.json")
    end
  
    def render("show.json", %{status: status}) do
      render_one(status, StatusView, "status.json")
    end
  
    def render("status.json", %{status: status}) do
      %{
        name: status.name,
        is_editable: status.is_editable,
        is_complete: status.is_complete
      }
    end
  end
  