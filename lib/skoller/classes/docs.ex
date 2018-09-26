defmodule Skoller.Classes.Docs do
  @moduledoc """
    A context module for classes and docs
  """

  alias Skoller.ClassDocs.Doc

  import Ecto.Query

  @doc """
    Gets oldest syllabus in each class.
  """
  def classes_with_syllabus_subquery() do
    from(d in Doc)
    |> where([d], d.is_syllabus == true)
    |> distinct([d], d.class_id)
    |> order_by([d], asc: d.inserted_at)
  end
end