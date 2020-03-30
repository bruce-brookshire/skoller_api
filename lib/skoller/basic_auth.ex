defmodule Skoller.BasicAuth do
  alias Skoller.Repo
  alias Skoller.Users
  alias Skoller.Users.User
  alias Skoller.Services.Authentication

  import Plug.Conn

  @job_listing_provider_id 600

  def authenticate(conn, email, password) do
    with %User{password_hash: password_hash, roles: roles} = user <-
           Users.get_user_by_email(email) |> Repo.preload([:roles]),
         true <- roles |> Enum.any?(&(&1.id == @job_listing_provider_id)),
         true <- Authentication.check_password(password, password_hash) do
      conn
      |> assign(:user, user)
    else
      _ ->
        conn |> send_resp(401, "Unauthorized") |> halt()
    end
  end

  def on_error(conn), do: send_resp(conn, 422, "") |> halt()
end
