defmodule SkollerWeb.Admin.UserView do
  use SkollerWeb, :view

  alias SkollerWeb.Admin.UserView
  alias SkollerWeb.RoleView
  alias SkollerWeb.StudentView
  alias SkollerWeb.ReportView

  def render("index.json", %{users: users}) do
    render_many(users, UserView, "user_detail.json")
  end

  def render("show.json", %{user: user}) do
    render_one(user, UserView, "user_detail.json")
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
    user.user
    |> render_one(UserView, "user.json")
    |> Map.merge(
      %{
        student: render_one(user.student, StudentView, "student.json"),
        roles: render_many(user.user.roles, RoleView, "role.json"),
        reports: render_many(user.user.reports, ReportView, "report.json")
      }
    )
  end
end
