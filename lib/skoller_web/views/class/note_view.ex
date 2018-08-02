defmodule SkollerWeb.Class.NoteView do
  def render("note.json", %{notes: notes}) do
    %{
      notes: notes.notes
    }
  end
end