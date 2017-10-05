defmodule ClassnavapiWeb.PageController do
  use ClassnavapiWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
