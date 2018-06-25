defmodule SkollerWeb.Api.V1.ForgotEmailController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.Users
  alias Skoller.Repo
  alias Skoller.Mailer
  alias SkollerWeb.Helpers.TokenHelper
  alias SkollerWeb.Helpers.RepoHelper
  alias SkollerWeb.AuthView

  import Bamboo.Email

  @from_email "noreply@skoller.co"
  @reset_password_route "/reset_password/"
  @forgot_email_text1 "You forgot your password? It's okay. None of us are perfect. Click " 
  @forgot_email_text2 " to reset it."
  @this_link "this link"

  def forgot(conn, %{"email" => email}) do
    case Users.get_user_by_email(email) do
      nil -> conn |> send_resp(204, "")
      user -> user |> send_forgot_pass_email()
    end
    conn |> send_resp(204, "")
  end

  def reset(conn, %{"password" => password}) do
    multi = Ecto.Multi.new
    |> Ecto.Multi.run(:user, Users.change_password(conn.assigns[:user], password))
    |> Ecto.Multi.run(:token, &TokenHelper.login(&1))

    case Repo.transaction(multi) do
      {:ok, %{} = auth} ->
        render(conn, AuthView, "show.json", auth: auth)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  defp send_forgot_pass_email(user) do
    {:ok, token} = user |> TokenHelper.short_token()
    user 
    |> forgot_pass_email(token)
    |> Mailer.deliver_later
  end

  defp forgot_pass_email(user, token) do
    new_email()
    |> to(user.email)
    |> from(@from_email)
    |> subject("Forgot Password")
    |> html_body("<p>" <> @forgot_email_text1 <> "<a href=" <> to_string(System.get_env("WEB_URL")) <> @reset_password_route <> token <> ">" <> @this_link <> "</a>" <> @forgot_email_text2 <> "</p>" <> Mailer.signature())
    |> text_body(@forgot_email_text1 <> to_string(System.get_env("WEB_URL")) <> @reset_password_route <> "?token=" <> token <> @forgot_email_text2 <> "\n" <> "\n" <> Mailer.text_signature())
  end
end