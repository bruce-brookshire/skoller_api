defmodule Skoller.AuthErrorHandler do
  @moduledoc false
  # This is automatically used by guardian.

  import Plug.Conn

  def auth_error(conn, {type, _reason}, _opts) do
    body = Poison.encode!(%{message: to_string(type)})
    send_resp(conn, 401, body)
  end
end
