defmodule ClassnavapiWeb.Class.HelpRequestView do
  use ClassnavapiWeb, :view

  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.HelpRequestView
  alias ClassnavapiWeb.Class.Help.TypeView

  def render("show.json", %{help_request: help_request}) do
    render_one(help_request, HelpRequestView, "help_request.json")
  end

  def render("help_request.json", %{help_request: help_request}) do
    help_request = help_request |> Repo.preload(:class_help_type)
    %{
      note: help_request.note,
      is_completed: help_request.is_completed,
      id: help_request.id,
      issue_status: render_one(help_request.class_help_type, TypeView, "type.json")
    }
  end
end
