defmodule ClassnavapiWeb.Class.HelpRequestView do
  use ClassnavapiWeb, :view

  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.HelpRequestView
  alias ClassnavapiWeb.Class.Help.TypeView
  alias ClassnavapiWeb.UserView

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
