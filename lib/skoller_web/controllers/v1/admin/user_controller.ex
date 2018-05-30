defmodule SkollerWeb.Api.V1.Admin.UserController do
  use SkollerWeb, :controller

  alias SkollerWeb.UserView
  alias SkollerWeb.UserListView
  alias SkollerWeb.Helpers.RepoHelper
  alias Skoller.Users
  alias Skoller.Admin.Users, as: AdminUsers
  alias Skoller.Repo

  import SkollerWeb.Helpers.AuthPlug
  
  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

  def create(conn, %{} = params) do
    case Users.create_user(params) do
      {:ok, %{user: user}} ->
        user = user |> Repo.preload(:student, force: true)
        render(conn, UserView, "show.json", user: user)
      {:error, failed_value} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  def index(conn, params) do
    users = AdminUsers.get_users(params)
    render(conn, UserListView, "index.json", users: users)
  end

  def show(conn, %{"id" => id}) do
    user = Users.get_user_by_id!(id)
    render(conn, UserView, "show.json", user: user)
  end

  def update(conn, %{"user_id" => user_id} = params) do
    user_old = Users.get_user_by_id!(user_id)

    case Users.update_user(user_old, params) do
      {:ok, %{user: user}} ->
        user = user |> Repo.preload(:student, force: true)
        render(conn, UserView, "show.json", user: user)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end
end
