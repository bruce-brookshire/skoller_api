defmodule ClassnavapiWeb.Helpers.ChatHelper do
  def is_liked([]), do: false
  def is_liked(enum, student_id) do
    enum |> Enum.any?(& &1.student_id == student_id)
  end
end