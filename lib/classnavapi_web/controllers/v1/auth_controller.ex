defmodule ClassnavapiWeb.Api.V1.AuthController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Repo
  alias ClassnavapiWeb.AuthView
  alias Classnavapi.User
  alias Classnavapi.Auth

  def create(conn, %{"email" => email, "password" => password}) do
    user = Repo.get_by(User, email: email)
    
    if Comeonin.Bcrypt.checkpw(password, user.password_hash) do
        {:ok, token, _} = Auth.encode_and_sign(%{:id => user.id}, %{typ: "access"})
        render(conn, AuthView, "show.json", token: token)
    else
        conn
           |> send_resp(401, "")
    end
  end
end