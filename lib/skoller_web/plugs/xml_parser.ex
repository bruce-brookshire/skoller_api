defmodule Plug.Parsers.XML do
  @behaviour Plug.Parsers

  import Plug.Conn

  def parse(conn, "text", "xml", _headers, opts) do
    read_body(conn, opts)
    |> decode()
  end

  def parse(conn, _, _, _, _), do: {:next, conn}

  defp decode({:ok, body, conn}) do
    {:ok, XmlToMap.naive_map(body), conn}
  end

  defp decode({:more, _, conn}) do
    {:error, :too_large, conn}
  end

  defp decode({:error, :timeout}) do
    raise Plug.TimeoutError
  end
end
