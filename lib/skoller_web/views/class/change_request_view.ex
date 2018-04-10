defmodule SkollerWeb.Class.ChangeRequestView do
  use SkollerWeb, :view

  alias Skoller.Repo
  alias SkollerWeb.Class.ChangeRequestView
  alias SkollerWeb.Class.Change.TypeView
  alias SkollerWeb.UserView

  def render("show.json", %{change_request: change_request}) do
    render_one(change_request, ChangeRequestView, "change_request.json")
  end

  def render("change_request.json", %{change_request: change_request}) do
    change_request = change_request |> Repo.preload([:class_change_type, :user])
    %{
      note: change_request.note,
      is_completed: change_request.is_completed,
      id: change_request.id,
      data: change_request.data,
      user: render_one(change_request.user, UserView, "user.json"),
      change_type: render_one(change_request.class_change_type, TypeView, "type.json")
    }
  end
end
