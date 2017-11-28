defmodule ClassnavapiWeb.Helpers.AuthPlug do

  alias Classnavapi.Repo
  alias Classnavapi.User

  import Plug.Conn

  def authenticate(conn, _) do
    case Repo.get(User, Guardian.Plug.current_resource(conn)) do
      %User{} = user ->
        user = user |> Repo.preload([:roles, :student])
        assign(conn, :user, user)
      nil ->
        conn
        |> send_resp(401, "")
        |> halt()
    end
  end

  def verify_role(conn, %{role: role}) do
    case Enum.any?(conn.assigns[:user].roles, & &1.id == role) do
      true -> conn
      false -> conn
              |> send_resp(401, "")
              |> halt()
    end
  end

  def verify_role(conn, %{roles: role}) do
    case Enum.any?(conn.assigns[:user].roles, &Enum.any?(role, fn x -> &1.id == x end)) do
      true -> conn
      false -> conn
              |> send_resp(401, "")
              |> halt()
    end
  end
end