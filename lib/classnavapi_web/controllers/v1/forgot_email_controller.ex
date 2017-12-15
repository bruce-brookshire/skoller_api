defmodule ClassnavapiWeb.Api.V1.ForgotEmailController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.User
  alias Classnavapi.Repo
  alias Classnavapi.Mailer
  alias ClassnavapiWeb.Helpers.TokenHelper
  alias ClassnavapiWeb.Helpers.RepoHelper

  import Bamboo.Email

  @from_email "support@skoller.co"

  def forgot(conn, %{"email" => email}) do
    case Repo.get_by(User, email: email) do
      nil -> conn |> send_resp(204, "")
      user -> user |> send_forgot_pass_email()
    end
    conn |> send_resp(204, "")
  end

  def reset(conn, %{"password" => password}) do
    changeset = User.changeset_update(conn.assigns[:user], password)
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
    |> Mailer.deliver_now
  end

  defp forgot_pass_email(user, token) do
    new_email()
    |> to("tyler@fortyau.com") #to(user.email)
    |> from(@from_email)
    |> subject("Test")
    |> text_body("?token=" <> token)
  end

  defp update_user(changeset) do
    Ecto.Multi.new
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.run(:token, &TokenHelper.login(&1))
  end
end