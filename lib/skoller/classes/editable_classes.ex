defmodule Skoller.Classes.EditableClasses do
  @moduledoc """
    A context module for editable classes
  """

  alias Skoller.Repo
  alias Skoller.Classes.Class

  import Ecto.Query

  @doc """
  Gets an editable `Skoller.Classes.Class` by id.

  ## Examples

      iex> Skoller.Classes.EditableClasses.get_editable_class_by_id(1)
      {:ok, %Skoller.Classes.Class{}}

  """
  def get_editable_class_by_id(id) do
    Repo.get_by(Class, id: id, is_editable: true)
  end

  @doc """
  Get editable classes in subquery form
  """
  def get_editable_classes_subquery() do
    from(class in Class)
    |> where([class], class.is_editable == true)
  end
end