defmodule SkollerWeb.Api.V1.NewUserController do
  use SkollerWeb, :controller
  
  alias Skoller.Repo
  alias Skoller.Users
  alias SkollerWeb.AuthView
  alias SkollerWeb.Helpers.TokenHelper
  alias SkollerWeb.Helpers.RepoHelper
  alias SkollerWeb.Sms

  def create(conn, params) do
    multi = Ecto.Multi.new
    |> Ecto.Multi.run(:user, &create_user(params, &1))
    |> Ecto.Multi.run(:token, &TokenHelper.login(&1.user))

    case Repo.transaction(multi) do
      {:ok, %{user: %{user: %{student: student} = user}, token: token}} ->
        student.phone |> Sms.verify_phone(student.verification_code)
        render(conn, AuthView, "show.json", [user: user, token: token])
      {:ok, %{} = auth} ->
        render(conn, AuthView, "show.json", auth: auth)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  defp create_user(params, _) do
    Users.create_user(params)
  end
end
