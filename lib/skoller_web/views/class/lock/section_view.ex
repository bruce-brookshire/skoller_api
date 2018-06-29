defmodule SkollerWeb.Class.Lock.SectionView do
  @moduledoc false
  use SkollerWeb, :view

  def render("section.json", %{section: section}) do
    %{
      id: section.id,
      name: section.name
    }
  end
end