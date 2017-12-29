defmodule ClassnavapiWeb.UserListView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.UserListView
  alias Classnavapi.Repo

  def render("index.json", %{users: users}) do
    render_many(users, UserListView, "user-detail.json", as: :user)
  end

  def render("user.json", %{user: user}) do
    %{
      id: user.id,
      email: user.email,
      avatar: user.pic_path,
      is_active: user.is_active
    }
  end

  def render("user_detail.json", %{user: user}) do
    user = user |> Repo.preload([:student, :roles])
    user
    |> render_one(UserListView, "user.json", as: :user)
    |> Map.merge(
      %{
        student: render_one(user.student, ClassnavapiWeb.StudentView, "student.json"),
        roles: render_many(user.roles, ClassnavapiWeb.RoleView, "role.json")
      }
    )
  end
end
