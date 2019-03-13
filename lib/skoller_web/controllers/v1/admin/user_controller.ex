defmodule SkollerWeb.Api.V1.Admin.UserController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias SkollerWeb.Admin.UserView
  alias SkollerWeb.Responses.MultiError
  alias Skoller.Users
  alias Skoller.Admin.Users, as: AdminUsers
  alias Skoller.Repo
  alias Skoller.Analytics.Documents

  import SkollerWeb.Plugs.Auth
  
  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}
  def create(conn, %{} = params) do
    case Users.create_user(params, [admin: true]) do
      {:ok, user} ->
        render(conn, UserView, "show.json", user: user)
      {:error, failed_value} ->
        conn
        |> MultiError.render(failed_value)
    end
  end

  def index(conn, params) do
    users = AdminUsers.get_users(params)
    render(conn, UserView, "index.json", users: users)
  end

  def show(conn, %{"id" => id}) do
    user = AdminUsers.get_user_by_id!(id)
    render(conn, UserView, "show.json", user: user)
  end

  def csv(conn, _params) do
    path = Documents.get_current_user_csv_path()

    case HTTPoison.get(path) do
      {:ok, %{status_code: 200, body: body}} -> 
        conn
          |> put_resp_content_type("text/csv")
          |> put_resp_header("content-disposition", ~s[attachment; filename="users.csv"; filename*="users.csv"])
          |> send_resp(200, body)
      _ -> conn |> send_resp(404, "csv not found")
        
    end
  end

  def update(conn, %{"user_id" => user_id} = params) do
    user_old = Users.get_user_by_id!(user_id)

    case Users.update_user(user_old, params, [admin: true]) do
      {:ok, %{user: user}} ->
        user = user |> Users.preload_student([], [force: true]) |> Repo.preload([:reports], force: true) |> Repo.preload([:roles], force: true)
        render(conn, UserView, "show.json", user: user)
      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end

  def points(conn, _params) do
    points = Skoller.Analytics.Students.get_student_points()
      
    conn 
      |> put_status(:ok)
      |> json(points)
  end
end
