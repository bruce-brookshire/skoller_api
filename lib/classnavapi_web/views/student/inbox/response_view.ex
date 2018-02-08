defmodule ClassnavapiWeb.Student.Inbox.ResponseView do
  use ClassnavapiWeb, :view

  alias ClassnavapiWeb.Student.Inbox.ResponseView

  def render("show.json", %{response: response}) do
    render_one(response, ResponseView, "response.json")
  end

  def render("response.json", %{response: response}) do
    %{
      response: response.response,
      is_reply: response.is_reply
    }
  end
end