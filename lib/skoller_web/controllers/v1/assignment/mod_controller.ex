defmodule SkollerWeb.Api.V1.Assignment.ModController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.Mods.Assignments
  alias SkollerWeb.Admin.ModView

  def index(conn, %{"assignment_id" => id}) do
    mods = Assignments.get_mods_by_assignment(id)
    conn |> render(ModView, "index.json", mods: mods)
  end
end