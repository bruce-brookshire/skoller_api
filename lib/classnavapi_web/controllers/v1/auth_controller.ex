defmodule ClassnavapiWeb.Api.V1.AuthController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Repo
  alias ClassnavapiWeb.AuthView
  
  def create(conn, %{"email" => email, "password" => password}) do
    user = Repo.get_by(Classnavapi.User, email: email)
    if user.password == password do
        {:ok, token, _} = Classnavapi.Auth.encode_and_sign(%{:id => user.id})
        render(conn, AuthView, "show.json", token: token)
    else
        conn
           |> send_resp(401, "")
    end
  end
end