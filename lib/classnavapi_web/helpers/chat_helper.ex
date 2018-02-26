defmodule ClassnavapiWeb.Helpers.ChatHelper do
  def is_liked([]), do: false
  def is_liked(enum, student_id) do
    enum |> Enum.any?(& to_string(&1.student_id) == to_string(student_id))
  end
end