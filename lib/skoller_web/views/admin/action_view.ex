defmodule SkollerWeb.Admin.ActionView do
  use SkollerWeb, :view

  alias SkollerWeb.UserView

  def render("action.json", %{action: action}) do
    %{
      is_manual: action.action.is_manual,
      is_accepted: action.action.is_accepted,
      user: render_one(action.user, UserView, "user_detail.json")
    }
  end
end