defmodule SkollerWeb.UserSocket do
  @moduledoc """
  Defines a websocket for Skoller. Runs authentication on the user when joining.
  """
  use Phoenix.Socket

  alias SkollerWeb.Plugs.Auth

  ## Channels
  channel "chat:*", SkollerWeb.ChatChannel

  ## Transports
  # transport :websocket, Phoenix.Transports.WebSocket,
  #   timeout: 45_000
  # transport :longpoll, Phoenix.Transports.LongPoll

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  def connect(%{"token" => token}, socket) do
    case Guardian.Phoenix.Socket.authenticate(socket, Skoller.Auth, token) do
      {:ok, authed_socket} ->
        case authed_socket |> Auth.get_auth_obj() do
          {:ok, user} ->
            {:ok, assign(authed_socket, :user, user)}
          {:error, _} -> :error
        end
      {:error, _} -> :error
    end
  end

  # Socket id's are topics that allow you to identify all sockets 
  # for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     SkollerWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(_socket), do: nil
end
