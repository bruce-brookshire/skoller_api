defmodule ClassnavapiWeb.Api.V1.ForgotEmailController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.User
  alias Classnavapi.Repo
  alias Classnavapi.Mailer
  alias ClassnavapiWeb.Helpers.TokenHelper
  alias ClassnavapiWeb.Helpers.RepoHelper
  alias ClassnavapiWeb.AuthView

  import Bamboo.Email

  @from_email "support@skoller.co"
  @base_url "https://www.skoller.co"
  @reset_password_route "/api/v1/reset"
  @forgot_email_text1 "You forgot your password? It's okay. None of us are perfect. Click " 
  @forgot_email_text2 " to reset it."
  @this_link "this link"

  def forgot(conn, %{"email" => email}) do
    case Repo.get_by(User, email: email) do
      nil -> conn |> send_resp(204, "")
      user -> user |> send_forgot_pass_email()
    end
    conn |> send_resp(204, "")
  end

  def reset(conn, %{"password" => password}) do
    changeset = User.changeset_update(conn.assigns[:user], %{"password" => password})
    multi = changeset |> update_user()

    case Repo.transaction(multi) do
      {:ok, %{} = auth} ->
        render(conn, AuthView, "show.json", auth: auth)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  defp send_forgot_pass_email(%User{} = user) do
    {:ok, token} = user |> TokenHelper.short_token()
    email = user 
    |> forgot_pass_email(token)
    |> Mailer.deliver_later
  end

  defp forgot_pass_email(user, token) do
    new_email()
    |> to("tyler@fortyau.com") #to(user.email)
    |> from(@from_email)
    |> subject("Forgot Password")
    |> html_body("<p>" <> @forgot_email_text1 <> "<a href=" <> @base_url <> @reset_password_route <> "?token=" <> token <> ">" <> @this_link <> "</a>" <> @forgot_email_text2 <> "</p>")
    |> text_body(@forgot_email_text1 <> @base_url <> @reset_password_route <> "?token=" <> token <> @forgot_email_text2)
  end

  defp update_user(changeset) do
    Ecto.Multi.new
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.run(:token, &TokenHelper.login(&1))
  end
end