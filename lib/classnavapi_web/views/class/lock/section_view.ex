defmodule ClassnavapiWeb.Class.Lock.SectionView do
  use ClassnavapiWeb, :view

  def render("section.json", %{section: section}) do
    %{
      id: section.id,
      name: section.name
    }
  end
end