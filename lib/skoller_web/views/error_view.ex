defmodule SkollerWeb.ErrorView do
  @moduledoc false
  use SkollerWeb, :view

  def render("error.json", %{error: error}) do
    %{
      error: error
    }
  end

  def render("401.html", _assigns) do
    "Not Authorized"
  end

  def render("404.html", _assigns) do
    "Page not found"
  end

  def render("500.html", _assigns) do
    "Internal server error"
  end

  # In case no render clause matches or no
  # template is found, let's render it as 500
  def template_not_found(_template, assigns) do
    render "500.html", assigns
  end
end
