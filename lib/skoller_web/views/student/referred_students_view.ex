defmodule SkollerWeb.Student.ReferredStudentsView do
  @moduledoc false

  use SkollerWeb, :view

  def render("referred_students.json", %{stuff: nil}) do
    %{stuff: "HI!"}
  end
end
