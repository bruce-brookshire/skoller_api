defmodule SkollerWeb.Api.V1.NewUserController do
  @moduledoc false
  
  use SkollerWeb, :controller
  
  alias Skoller.Repo
  alias Skoller.Users
  alias SkollerWeb.AuthView
  alias Skoller.Token
  alias SkollerWeb.Responses.MultiError
  alias SkollerWeb.Sms

  def create(conn, params) do
    multi = Ecto.Multi.new
    |> Ecto.Multi.run(:user, &create_user(params, &1))
    |> Ecto.Multi.run(:token, &Token.login(&1.user.id))
    |> Repo.transaction()

    case multi do
      {:ok, %{user: %{user: user}, token: token}} ->
        user = user |> Repo.preload(:student, force: true)
        user.student |> send_verification_text()
        render(conn, AuthView, "show.json", [user: user, token: token])
      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end

  defp send_verification_text(nil), do: nil
  defp send_verification_text(student) do
    student.phone |> Sms.verify_phone(student.verification_code)
  end

  defp create_user(params, _) do
    Users.create_user(params)
  end
end
