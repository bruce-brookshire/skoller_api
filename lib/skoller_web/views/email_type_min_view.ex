defmodule SkollerWeb.EmailTypeMinView do
  @moduledoc false
  use SkollerWeb, :view

  alias SkollerWeb.EmailTypeMinView

  def render("index.json", %{email_types: email_types}) do
    render_many(email_types, EmailTypeMinView, "email_type_min.json", as: :email_type)
  end

  def render("email_type_min.json", %{email_type: email_type}) do
    %{
      id: email_type.id,
      name: email_type.name
    }
  end
end
