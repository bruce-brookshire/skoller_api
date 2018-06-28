defmodule SkollerWeb.Class.Lock.SectionView do
  use SkollerWeb, :view

  def render("section.json", %{section: section}) do
    %{
      id: section.id,
      name: section.name
    }
  end
end