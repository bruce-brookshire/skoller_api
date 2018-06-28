defmodule SkollerWeb.UserListView do
  use SkollerWeb, :view

  alias SkollerWeb.UserListView
  alias Skoller.Repo

  def render("index.json", %{users: users}) do
    render_many(users, UserListView, "user_detail.json", as: :user)
  end

  def render("user.json", %{user: user}) do
    %{
      id: user.id,
      email: user.email,
      avatar: user.pic_path,
      is_active: user.is_active
    }
  end

  def render("user_detail.json", %{user: %{user: user, student: student}}) do
    user = user |> Repo.preload([:roles])
    user
    |> render_one(UserListView, "user.json", as: :user)
    |> Map.merge(
      %{
        student: render_one(student, SkollerWeb.StudentView, "student.json"),
        roles: render_many(user.roles, SkollerWeb.RoleView, "role.json")
      }
    )
  end
end
