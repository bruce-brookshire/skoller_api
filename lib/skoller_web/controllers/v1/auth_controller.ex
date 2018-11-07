defmodule SkollerWeb.Api.V1.AuthController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.Users
  alias Skoller.Devices
  alias SkollerWeb.AuthView
  alias Skoller.Token
  alias Skoller.Services.Authentication
  
  import SkollerWeb.Plugs.Auth

  plug :verify_user_exists

  def login(conn, %{"email" => email, "password" => password}) do
    user = Users.get_user_by_email(email)

    if Authentication.check_password(password, user.password_hash) do
        {:ok, token} = Token.login(user.id)
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
    Devices.get_device_by_attributes!(udid, type, user.id)
    |> Devices.delete_device!()
    conn
  end
  def deregister_devices(conn, _params), do: conn
end