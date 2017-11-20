defmodule ClassnavapiWeb.Helpers.AuthPlug do

  alias Classnavapi.Repo
  alias Classnavapi.User

  import Plug.Conn

  def authenticate(conn, _) do
    case Repo.get(User, Guardian.Plug.current_resource(conn)) do
      %User{} = user ->
        assign(conn, :user, user)
      nil ->
        conn
        |> send_resp(401, "")
        |> halt()
    end
  end

end