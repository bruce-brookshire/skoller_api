defmodule SkollerWeb.Class.ChangeRequestView do
  @moduledoc false
  use SkollerWeb, :view

  alias Skoller.Repo
  alias SkollerWeb.Class.ChangeRequestView
  alias SkollerWeb.Class.Change.TypeView
  alias SkollerWeb.UserView

  def render("show.json", %{change_request: change_request}) do
    render_one(change_request, ChangeRequestView, "change_request.json")
  end
  
  def render("show.json", %{change_request_member: member}) do
    render_one(member, ChangeRequestView, "change_request_member.json", as: :member)
  end

  def render("index.json", %{change_request_members: members}) do
    render_many(members, ChangeRequestView, "change_request_member.json", as: :member)
  end

  def render("change_request.json", %{change_request: change_request}) do
    change_request = change_request |> Repo.preload([:class_change_type, :user, :class_change_request_members])
    %{
      id: change_request.id,
      change_type: render_one(change_request.class_change_type, TypeView, "type.json"),
      inserted_at: change_request.inserted_at,
      updated_at: change_request.updated_at,
      members: render_many(change_request.class_change_request_members, ChangeRequestView, "change_request_member.json", as: :member),
      is_completed: change_request.is_completed,
      note: change_request.note,
      user: render_one(change_request.user, UserView, "user.json"),
    }
  end

  def render("change_request_member.json", %{member: member}) do
    %{
      id: member.id, 
      member_name: member.name,
      member_value: member.value,
      change_request_id: member.class_change_request_id
    }
  end
end
