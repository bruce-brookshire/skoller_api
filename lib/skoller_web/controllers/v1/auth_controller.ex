defmodule SkollerWeb.Api.V1.AuthController do
  @moduledoc false

  use SkollerWeb, :controller

  alias Skoller.Users
  alias Skoller.Students
  alias Skoller.Students.Student
  alias Skoller.Devices
  alias SkollerWeb.AuthView
  alias Skoller.Token
  alias Skoller.Services.Authentication
  alias Skoller.Payments

  import SkollerWeb.Plugs.Auth

  plug :verify_user_exists

  def login(conn, %{"email" => email, "password" => password}) do
    user = Users.get_user_by_email(email)

    if Authentication.check_password(password, user.password_hash) do
      subscriptions = Task.async(fn  -> get_subscription_list(user.id)   end)
      {:ok, token} = Token.login(user.id)
      token = Map.new(%{token: token})
              |> Map.merge(%{user: user})
              |> Map.merge(%{subscriptions: Task.await(subscriptions, :infinity)})

      user
      |> Users.update_user(%{last_login: DateTime.utc_now()})

      conn
      |> put_view(AuthView)
      |> render("show.json", auth: token)
    else
      conn
      |> send_resp(401, "")
    end
  end

  def student_login(conn, %{"verification_code" => code, "phone" => phone}) do
    case Students.get_student_by_phone(phone) do
      %{verification_code: verification_code, login_attempt: last_attempt} = student
      when verification_code == code ->
        if DateTime.diff(DateTime.utc_now(), last_attempt, :seconds) <= 300 do
          user = Users.get_user_by_student_id(student.id)
          subscriptions = Task.async(fn  -> get_subscription_list(user.id) end)
          user
          |> Users.update_user(%{last_login: DateTime.utc_now()})

          {:ok, token} = Token.long_token(user.id)
          token = Map.new(%{token: token})
                  |> Map.merge(%{user: user})
                  |> Map.merge(%{subscriptions: Task.await(subscriptions, :infinity)})

          conn
          |> put_view(AuthView)
          |> render("show.json", auth: token)
        else
          conn
          |> send_resp(401, "Verification code timed out")
        end

      _ ->
        conn
        |> send_resp(401, "Invalid code")
    end
  end

  def student_login(conn, %{"phone" => phone}) do
    case Students.get_student_by_phone(phone) do
      %Student{} = student ->
        case Students.create_login_attempt(student) do
          {:ok, _} ->
            conn
            |> send_resp(204, "")

          _ ->
            conn
            |> send_resp(422, "Failed to update student")
        end

      value ->
        IO.inspect(value)
        conn
        |> send_resp(404, "User not found")
    end
  end

  def logout(conn, params) do
    conn
    |> deregister_devices(params)
    |> send_resp(204, "")
  end

  def token(conn, _params) do
    conn
    |> put_view(AuthView)
    |> render("show.json", auth: conn.assigns[:user])
  end

  def deregister_devices(
        %{
          assigns: %{
            user: user
          }
        } = conn,
        %{"udid" => udid, "type" => type}
      ) do
    Devices.get_device_by_attributes!(udid, type, user.id)
    |> Devices.delete_device!()

    conn
  end

  def deregister_devices(conn, _params), do: conn

  defp get_subscription_list(user_id)do
    with %Skoller.Payments.Stripe{customer_id: customer_id} <- Payments.get_stripe_by_user_id(user_id),
         {:ok, %Stripe.List{data: subscriptions}} = Stripe.Subscription.list(%{customer: customer_id}) do
      subscriptions
    else
      _ -> nil
    end
  end
end
