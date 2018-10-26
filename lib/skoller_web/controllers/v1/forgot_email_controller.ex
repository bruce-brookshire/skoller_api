defmodule SkollerWeb.Api.V1.ForgotEmailController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.Users
  alias Skoller.Repo
  alias Skoller.Token
  alias SkollerWeb.Responses.MultiError
  alias SkollerWeb.AuthView
  alias Skoller.Services.TriggeredEmail

  @forgot_subject "Forgot Password"
  @reset_password_route "/reset_password"

  def forgot(conn, %{"email" => email}) do
    case Users.get_user_by_email(email) do
      nil -> nil
      user -> user |> send_forgot_pass_email()
    end
    conn |> send_resp(204, "")
  end

  def reset(conn, %{"password" => password}) do
    multi = Ecto.Multi.new
    |> Ecto.Multi.run(:user, &change_password(conn.assigns[:user], password, &1))
    |> Ecto.Multi.run(:token, &Token.login(&1.user.id))

    case Repo.transaction(multi) do
      {:ok, %{} = auth} ->
        render(conn, AuthView, "show.json", auth: auth)
      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end

  defp change_password(user, password, _) do
    Users.change_password(user, password)
  end

  defp send_forgot_pass_email(user) do
    {:ok, token} = user.id |> Token.short_token()
    reset_path = to_string(System.get_env("WEB_URL")) <> @reset_password_route <> "?token=" <> token
    TriggeredEmail.send_email(user.email, @forgot_subject, :forgot_password, [reset_path: reset_path])
  end
end