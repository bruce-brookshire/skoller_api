defmodule SkollerWeb.Endpoint do
  @moduledoc """
  The endpoint is the http handler. It manages routes, sessions, loggers, sockets, and parsers.
  """
  use Phoenix.Endpoint, otp_app: :skoller

  socket "/socket", SkollerWeb.UserSocket,
    websocket: [timeout: 45_000]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/", from: :skoller, gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Logger

  plug SkollerWeb.Plugs.SNSHeader



  plug Plug.Parsers,
  parsers: [:urlencoded, :multipart, :json, {:xml, length: 100_000_000}],
  length: 100_000_000,
  pass: ["*/*"],
  json_decoder: Jason

  plug Plug.MethodOverride
  plug Plug.Head

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug Plug.Session,
    store: :cookie,
    key: "_skoller_key",
    signing_salt: "EW+VIcw9"

  plug CORSPlug

  plug SkollerWeb.Router

  @doc """
  Callback invoked for dynamically configuring the endpoint.

  It receives the endpoint configuration and checks if
  configuration should be loaded from the system environment.
  """
  def init(_key, config) do
    if config[:load_from_system_env] do
      port = System.get_env("PORT") || raise "expected the PORT environment variable to be set"
      {:ok, Keyword.put(config, :http, [:inet6, port: port])}
    else
      {:ok, config}
    end
  end
end
