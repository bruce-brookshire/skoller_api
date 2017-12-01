defmodule ClassnavapiWeb.Api.V1.AuthController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Repo
  alias ClassnavapiWeb.AuthView
  alias Classnavapi.User
  alias ClassnavapiWeb.Helpers.TokenHelper
  
  import ClassnavapiWeb.Helpers.AuthPlug

  plug :verify_user_exists

  def login(conn, %{"email" => email, "password" => password}) do
    user = Repo.get_by(User, email: email)

    if Comeonin.Bcrypt.checkpw(password, user.password_hash) do
        {:ok, token} = TokenHelper.login(user)
        token = Map.new(%{token: token}) |> Map.merge(%{user: user})
        render(conn, AuthView, "show.json", auth: token)
    else
        conn
           |> send_resp(401, "")
    end
  end

  def token(conn, _params) do
    render(conn, AuthView, "show.json", auth: conn.assigns[:user])
  end
end