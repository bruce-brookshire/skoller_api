defmodule SkollerWeb.Class.Help.TypeView do
    use SkollerWeb, :view
  
    alias SkollerWeb.Class.Help.TypeView
  
    def render("index.json", %{types: types}) do
      render_many(types, TypeView, "type.json")
    end
  
    def render("show.json", %{type: type}) do
      render_one(type, TypeView, "type.json")
    end
  
    def render("type.json", %{type: type}) do
      %{
        id: type.id,
        name: type.name
      }
    end
  end
  