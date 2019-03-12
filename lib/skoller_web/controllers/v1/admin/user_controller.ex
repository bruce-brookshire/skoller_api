defmodule SkollerWeb.Api.V1.Admin.UserController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias SkollerWeb.Admin.UserView
  alias SkollerWeb.Responses.MultiError
  alias Skoller.Users
  alias Skoller.Admin.Users, as: AdminUsers
  alias Skoller.Repo
  alias Skoller.Students.StudentAnalytics
  alias Skoller.AnalyticUpload

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
    filename = get_filename()

    content = csv_users()
    scope = %{:id => filename, :dir => "user_csv"}

    
    case AnalyticUpload.store({content, scope}) do
      {:ok, inserted} ->
        conn |> send_resp(200, AnalyticUpload.url({inserted, scope}))
      {:error, error} ->
        conn |> send_resp(404, "not found")
    end
    # conn
    # |> put_resp_content_type("text/csv")
    # |> put_resp_header("content-disposition", ~s[attachment; filename="#{filename}"; filename*="#{filename}"])
    # |> send_resp(200, csv_users())
  end
  defp get_filename() do
    now = DateTime.utc_now
    "Users-#{now.month}_#{now.day}_#{now.year}_#{now.hour}_#{now.minute}_#{now.second}.csv"
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

  defp csv_users() do
    # StudentAnalytics.get_student_analytics()
    [
      ["Account Creation Date",
      "First Name",
      "Last Name",
      "Email",
      "Phone #",
      "Phone # Verified?",
      "Main School",
      "Graduation Year",
      "Current Classes",
      "Current Classes Set Up",
      "Total Classes",
      "Total Classes Set Up",
      "Referral Organization",
      "Active Assignments",
      "Inactive Assignments",
      "Grades Entered",
      "Created Mods",
      "Created Assignments"]
    ]
      |> CSV.encode
      |> Enum.to_list
      |> add_headers
      |> to_string
  end

  defp add_headers(list) do

    [
      "Account Creation Date," <>
      "First Name," <>
      "Last Name," <> 
      "Email," <> 
      "Phone #," <>
      "Phone # Verified?," <>
      "Main School," <>
      "Graduation Year," <> 
      "Current Classes," <>
      "Current Classes Set Up," <>
      "Total Classes," <>
      "Total Classes Set Up," <>
      "Referral Organization," <>
      "Active Assignments," <>
      "Inactive Assignments," <>
      "Grades Entered," <>
      "Created Mods," <>
      "Created Assignments\r\n"
      | list
    ]
  end
end
