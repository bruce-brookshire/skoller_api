defmodule SkollerWeb.Api.V1.ForgotEmailController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.Users
  alias Skoller.Repo
  alias Skoller.Services.Mailer
  alias Skoller.Token
  alias SkollerWeb.Responses.MultiError
  alias SkollerWeb.AuthView
  alias Skoller.Services.Email

  import Bamboo.Email

  @from_email "noreply@skoller.co"
  @reset_password_route "/reset_password"
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
    user 
    |> forgot_pass_email(token)
    |> Mailer.deliver_later
  end

  defp forgot_pass_email(user, token) do
    new_email()
    |> to(user.email)
    |> from(@from_email)
    |> subject("Forgot Password")
    |> html_body("<p>" <> @forgot_email_text1 <> "<a href=" <> to_string(System.get_env("WEB_URL")) <> @reset_password_route <> "?token=" <> token <> ">" <> @this_link <> "</a>" <> @forgot_email_text2 <> "</p>" <> Email.signature())
    |> text_body(@forgot_email_text1 <> to_string(System.get_env("WEB_URL")) <> @reset_password_route <> "?token=" <> token <> @forgot_email_text2 <> "\n" <> "\n" <> Email.text_signature())
  end
end