defmodule SkollerWeb.Api.V1.Admin.UserController do
  @moduledoc false

  use SkollerWeb, :controller

  alias SkollerWeb.Admin.UserView
  alias SkollerWeb.AuthView
  alias SkollerWeb.Responses.MultiError
  alias Skoller.Users
  alias Skoller.Admin.Users, as: AdminUsers
  alias Skoller.Repo
  alias Skoller.Payments

  import SkollerWeb.Plugs.Auth

  @admin_role 200

  plug :verify_role, %{role: @admin_role}

  def create(conn, %{} = params) do
    case Users.create_user(params, admin: true) do
      {:ok, user} ->
        conn
        |> put_view(UserView)
        |> render("show.json", user: user)

      {:error, failed_value} ->
        conn
        |> MultiError.render(failed_value)
    end
  end

  def index(conn, params) do
    users = AdminUsers.get_users(params)

    conn
    |> put_view(UserView)
    |> render("index.json", users: users)
  end

  def show(conn, %{"id" => id}) do
    user = AdminUsers.get_user_by_id!(id)

    subscriptions = get_subscription_list(user.id)

    conn
    |> put_view(UserView)
    |> render("user_subscriptions.json", user: user, subscriptions: subscriptions)
  end

  def update(conn, %{"user_id" => user_id} = params) do
    user_old = Users.get_user_by_id!(user_id)

    case Users.update_user(user_old, params, admin_update: true) do
      {:ok, %{user: user}} ->
        user =
          user
          |> Users.preload_student([], force: true)
          |> Repo.preload([:reports], force: true)
          |> Repo.preload([:roles], force: true)

        conn
        |> put_view(UserView)
        |> render("show.json", user: user)

      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end

  def points(conn, _params) do
    points = Skoller.EnrolledStudents.get_student_points()

    conn
    |> put_status(:ok)
    |> json(points)
  end

  def reset_password(conn, %{"password" => password, "user_id" => user_id}) do
    user = Users.get_user_by_id!(user_id)

    case Users.change_password(user, password) do
      {:ok, %{} = auth} ->
        conn
        |> put_view(AuthView)
        |> render("show.json", auth: auth)

      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end

  def set_endless_trial(conn, %{"user_id" => user_id}) do
    Repo.get(Skoller.Users.User, user_id)
    |> Skoller.Users.Trial.set_endless_trial()

    json(conn, [])
  end

  defp get_subscription_list(user_id) do
    with %Skoller.Payments.Stripe{customer_id: customer_id} <-
           Payments.get_stripe_by_user_id(user_id),
         {:ok, %Stripe.List{data: subscriptions}} <-
           Stripe.Subscription.list(%{customer: customer_id}) do
      subscriptions
    else
      _ -> []
    end
  end
end
