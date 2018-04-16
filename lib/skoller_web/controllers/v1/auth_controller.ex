defmodule SkollerWeb.Api.V1.AuthController do
  use SkollerWeb, :controller

  alias Skoller.Users
  alias Skoller.Repo
  alias SkollerWeb.AuthView
  alias Skoller.User.Device
  alias SkollerWeb.Helpers.TokenHelper
  
  import SkollerWeb.Helpers.AuthPlug

  plug :verify_user_exists

  def login(conn, %{"email" => email, "password" => password}) do
    user = Users.get_user_by_email(email)

    if Comeonin.Bcrypt.checkpw(password, user.password_hash) do
        {:ok, token} = TokenHelper.login(user)
        token = Map.new(%{token: token}) |> Map.merge(%{user: user})
        render(conn, AuthView, "show.json", auth: token)
    else
        conn
           |> send_resp(401, "")
    end
  end

  def logout(conn, params) do
    conn
    |> deregister_devices(params)
    |> send_resp(204, "")
  end

  def token(conn, _params) do
    render(conn, AuthView, "show.json", auth: conn.assigns[:user])
  end

  def deregister_devices(%{assigns: %{user: user}} = conn, %{"udid" => udid, "type" => type}) do
    Device
    |> Repo.get_by!(udid: udid, type: type, user_id: user.id)
    |> Repo.delete!()

    conn
  end
  def deregister_devices(conn, _params), do: conn
end