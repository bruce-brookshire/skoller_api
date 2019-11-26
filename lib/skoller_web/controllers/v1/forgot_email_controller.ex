defmodule SkollerWeb.Api.V1.ForgotEmailController do
  @moduledoc false

  use SkollerWeb, :controller

  alias Skoller.Users
  alias SkollerWeb.Responses.MultiError
  alias SkollerWeb.AuthView

  def forgot(conn, %{"email" => email}) do
    Users.forgot_password(email)
    conn |> send_resp(204, "")
  end

  def reset(conn, %{"password" => password}) do
    case Users.change_password(conn.assigns[:user], password) do
      {:ok, %{} = auth} ->
        conn
        |> put_view(AuthView)
        |> render("show.json", auth: auth)

      {:error, _, failed_value, _} ->
        conn
        |> MultiError.render(failed_value)
    end
  end
end
