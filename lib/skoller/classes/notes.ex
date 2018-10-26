defmodule Skoller.Notes do
  @moduledoc """
  A context module for class notes.
  """

  alias Skoller.Classes.Note
  alias Skoller.Repo

  @doc """
  Creates a class note.
  """
  def create_note(attrs) do
    %Note{}
    |> Note.changeset(attrs)
    |> Repo.insert()
  end
end