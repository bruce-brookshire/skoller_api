defmodule SkollerWeb.Api.V1.Admin.UserController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias SkollerWeb.Admin.UserView
  alias SkollerWeb.Responses.MultiError
  alias Skoller.Users
  alias Skoller.Admin.Users, as: AdminUsers
  alias Skoller.StudentClasses
  alias Skoller.Users.Students
  alias Skoller.EnrolledStudents
  alias Skoller.ClassStatuses.Classes
  alias Skoller.Services.Formatter

  import SkollerWeb.Plugs.Auth
  
  @admin_role 200

  @class_complete_status 1400
  
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
    users = Students.get_student_users()
    filename = get_filename()
    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", ~s[attachment; filename="#{filename}"; filename*="#{filename}"])
    |> send_resp(200, csv_users(users))
  end
  defp get_filename() do
    now = DateTime.utc_now
    "Users-#{now.month}_#{now.day}_#{now.year}_#{now.hour}_#{now.minute}_#{now.second}.csv"
  end

  def update(conn, %{"user_id" => user_id} = params) do
    user_old = Users.get_user_by_id!(user_id)

    case Users.update_user(user_old, params, [admin: true]) do
      {:ok, %{user: user}} ->
        user = user |> Students.preload_student()
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

  defp csv_users(users) do
    users
    |> Enum.map(&get_row_data(&1))
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
      "Majors and Minors\r\n"
      | list
    ]
  end

  defp get_row_data(user) do
    user = user |> Users.preload_student([:primary_school, :fields_of_study, {:student_classes, [:class]}])
    enrolled_classes = EnrolledStudents.get_enrolled_classes_by_student_id(user.student_id)
    [
      "#{user.inserted_at.month}/#{user.inserted_at.day}/#{user.inserted_at.year} #{user.inserted_at.hour}:#{user.inserted_at.minute}:#{user.inserted_at.second}",
      user.student.name_first,
      user.student.name_last,
      user.email,
      Formatter.phone_to_string(user.student.phone),
      user.student.is_verified,
      (if user.student.primary_school != nil, do: user.student.primary_school.name, else: get_most_common_school_name(enrolled_classes)),
      user.student.grad_year,
      Enum.count(enrolled_classes),
      Enum.count(enrolled_classes, fn sc -> sc.class.class_status_id == @class_complete_status end),
      Enum.count(user.student.student_classes),
      Enum.count(user.student.student_classes, fn sc -> sc.class.class_status_id == @class_complete_status end),
      Enum.reduce(user.student.fields_of_study, "", fn f, acc -> acc <> f.field <> "|" end)
    ]
  end

  defp get_needs_syllabus_classes(student_classes) do
    student_classes
    |> Enum.filter(&Classes.class_needs_setup?(&1))
    |> Enum.count
  end

  defp get_most_common_school_name(student_classes) do
    case StudentClasses.get_most_common_school(student_classes) do
      nil -> ""
      school -> school.name
    end
  end
end
