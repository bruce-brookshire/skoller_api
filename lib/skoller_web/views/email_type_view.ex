defmodule SkollerWeb.EmailTypeView do
  @moduledoc false
  use SkollerWeb, :view

  alias SkollerWeb.EmailTypeView

  def render("index.json", %{email_types: email_types}) do
    render_many(email_types, EmailTypeView, "email_type.json")
  end

  def render("show.json", %{email_type: email_type}) do
    render_one(email_type, EmailTypeView, "email_type.json")
  end

  def render("email_type.json", %{email_type: email_type}) do
    %{
      id: email_type.id,
      name: email_type.name
    }
  end
end
