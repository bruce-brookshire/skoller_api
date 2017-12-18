defmodule ClassnavapiWeb.UserView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.UserView
  alias Classnavapi.Repo

  def render("index.json", %{users: users}) do
    render_many(users, UserView, "user.json")
  end

  def render("show.json", %{user: user}) do
    render_one(user, UserView, "user_detail.json")
  end

  def render("user.json", %{user: user}) do
    %{
      id: user.id,
      email: user.email,
      avatar: user.pic_path
    }
  end

  def render("user_detail.json", %{user: user}) do
    user = user |> Repo.preload([:student, :roles])
    user
    |> render_one(UserView, "user.json")
    |> Map.merge(
      %{
        student: render_one(user.student, ClassnavapiWeb.StudentView, "student.json"),
        roles: render_many(user.roles, ClassnavapiWeb.RoleView, "role.json")
      }
    )
  end
end
