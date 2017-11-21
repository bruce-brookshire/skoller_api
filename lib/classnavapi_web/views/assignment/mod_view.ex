defmodule ClassnavapiWeb.Assignment.ModView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.Class.ModView
  alias Classnavapi.Repo

  def render("index.json", %{mods: mods}) do
    render_many(mods, ModView, "mod.json")
  end

  def render("show.json", %{mod: mod}) do
    render_one(mod, ModView, "mod.json")
  end

  def render("mod.json", %{mod: mod}) do
    mod = mod |> Repo.preload(:assignment_mod_type)
    %{
      id: mod.id,
      data: mod.data,
      mod_type: mod.assignment_mod_type.name
    }
  end
end
