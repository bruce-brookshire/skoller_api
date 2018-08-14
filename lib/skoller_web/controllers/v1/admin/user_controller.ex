defmodule SkollerWeb.Api.V1.Admin.UserController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias SkollerWeb.Admin.UserView
  alias SkollerWeb.Responses.MultiError
  alias Skoller.Users
  alias Skoller.Admin.Users, as: AdminUsers
  alias Skoller.Repo
  alias Skoller.Dates

  import SkollerWeb.Plugs.Auth
  
  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

  def create(conn, %{} = params) do
    case Users.create_user(params) do
      {:ok, %{user: user}} ->
        user = user |> Repo.preload([:student, :reports], force: true)
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
    users = Users.get_student_users()
    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", "attachment; filename=\"Users-" <> to_string(DateTime.utc_now) <>  "\"")
    |> send_resp(200, csv_users(users))
  end

  def update(conn, %{"user_id" => user_id} = params) do
    user_old = Users.get_user_by_id!(user_id)

    case Users.update_user(user_old, params) do
      {:ok, %{user: user}} ->
        user = user |> Repo.preload([:student, :reports], force: true)
        render(conn, UserView, "show.json", user: user)
      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end

  defp csv_users(users) do
    users
    |> Enum.map(&get_row_data(&1))
    |> CSV.encode
    |> Enum.to_list
    |> add_headers
    |> to_string
  end

  def add_headers(list) do
    ["email,first,last,phone,created date\r\n" | list]
  end

  def get_row_data(user) do
    user = user |> Repo.preload(:student)
    [user.email, user.student.name_first, user.student.name_last, format_phone(user.student.phone), format_date(user.inserted_at)]
  end

  def format_phone(phone) do
    (phone |> String.slice(0, 3)) <> "-" <> (phone |> String.slice(3, 3)) <> "-" <> (phone |> String.slice(6, 4))
  end

  def format_date(naive_date_time) do
    date_time = DateTime.from_naive!(naive_date_time, "Etc/UTC")
    {:ok, time} = Time.new(date_time.hour, date_time.minute, date_time.second)
    date = DateTime.to_date(date_time)

    to_string(date) <> " " <> to_string(time)
  end
end
