defmodule SkollerWeb.Admin.ActionView do
  use SkollerWeb, :view

  def render("action.json", %{action: action}) do
    %{
      is_manual: action.action.is_manual,
      is_accepted: action.action.is_accepted,
      name_first: action.student.name_first,
      name_last: action.student.name_last,
      email: action.user.email
    }
  end
end