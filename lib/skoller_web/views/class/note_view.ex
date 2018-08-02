defmodule SkollerWeb.Class.NoteView do
  use SkollerWeb, :view

  def render("note.json", %{note: note}) do
    %{
      notes: note.notes
    }
  end
end