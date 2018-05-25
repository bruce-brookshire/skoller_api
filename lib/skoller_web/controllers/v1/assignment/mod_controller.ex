defmodule SkollerWeb.Api.V1.Assignment.ModController do
  use SkollerWeb, :controller

  alias Skoller.Assignments.Mods
  alias SkollerWeb.Admin.ModView

  def index(conn, %{"assignment_id" => id}) do
    mods = Mods.get_mods_by_assignment(id)
    conn |> render(ModView, "index.json", mods: mods)
  end
end