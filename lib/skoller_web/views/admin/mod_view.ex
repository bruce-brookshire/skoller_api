defmodule SkollerWeb.Admin.ModView do
  @moduledoc false
  use SkollerWeb, :view

  alias Skoller.Repo
  alias SkollerWeb.Admin.ModView
  alias SkollerWeb.Admin.ActionView

  def render("index.json", %{mods: mods}) do
    render_many(mods, ModView, "mod.json")
  end

  def render("mod.json", %{mod: %{action: actions} = mod}) do
    mod = mod |> Repo.preload([:assignment_mod_type])
    %{
      id: mod.id,
      data: mod.data,
      mod_type: mod.assignment_mod_type.name,
      mod_created_at: mod |> get_inserted_at(),
      actions: render_many(actions, ActionView, "action.json"),
      is_auto_update: mod.is_auto_update,
      is_private: mod.is_private
    }
  end

  defp get_inserted_at(mod) do
    {:ok, date} = mod.inserted_at 
    |> DateTime.from_naive("Etc/UTC")
    date
    |> DateTime.to_iso8601()
  end
end