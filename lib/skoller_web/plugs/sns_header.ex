defmodule SkollerWeb.Plugs.SNSHeader do
  import Plug.Conn

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    case conn |> get_req_header("content-type") |> List.first() do
      "text/plain" -> 
        case conn |> get_req_header("x-amz-sns-message-type") do
          [] -> conn
          _list -> put_req_header(conn, "content-type", "application/json")
        end
      _type -> conn
    end
  end
end