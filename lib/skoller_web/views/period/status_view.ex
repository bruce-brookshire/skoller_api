defmodule SkollerWeb.Period.StatusView do
  @moduledoc false
  use SkollerWeb, :view

  def render("status.json", %{status: status}) do
    %{
      name: status.name,
      id: status.id
    }
  end
end