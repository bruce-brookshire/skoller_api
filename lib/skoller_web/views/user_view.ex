defmodule SkollerWeb.UserView do
  @moduledoc false
  use SkollerWeb, :view

  alias SkollerWeb.UserView
  alias Skoller.Repo
  alias ExMvc.View

  def render("index.json", %{users: users}) do
    render_many(users, UserView, "user.json")
  end

  def render("show.json", %{user: user}) do
    render_one(user, UserView, "user_detail.json")
  end

  def render("user.json", %{user: user}),
    do:
      Map.take(user, [:id, :email, :pic_path, :is_active])
      |> Map.put(:org_owners, View.render_association(user.org_owners))
      |> Map.put(:org_group_owners, View.render_association(user.org_members))

  def render("user_detail.json", %{user: user}) do
    user = user |> Repo.preload([:student, :roles, :org_owners, :org_members])

    user
    |> render_one(UserView, "user.json")
    |> Map.merge(%{
      student: render_one(user.student, SkollerWeb.StudentView, "student.json"),
      roles: render_many(user.roles, SkollerWeb.RoleView, "role.json")
    })
  end
end
