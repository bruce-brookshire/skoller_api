defmodule SkollerWeb.Class.HelpRequestView do
  @moduledoc false
  use SkollerWeb, :view

  alias Skoller.Repo
  alias SkollerWeb.Class.HelpRequestView
  alias SkollerWeb.Class.Help.TypeView
  alias SkollerWeb.UserView

  def render("show.json", %{help_request: help_request}) do
    render_one(help_request, HelpRequestView, "help_request.json")
  end

  def render("help_request.json", %{help_request: help_request}) do
    help_request = help_request |> Repo.preload([:class_help_type, :user])
    %{
      note: help_request.note,
      is_completed: help_request.is_completed,
      id: help_request.id,
      user: render_one(help_request.user, UserView, "user.json"),
      help_type: render_one(help_request.class_help_type, TypeView, "type.json")
    }
  end
end
