defmodule ClassnavapiWeb.Helpers.ChatHelper do
  defp is_liked([]), do: false
  defp is_liked(enum, student_id) do
    enum |> Enum.find(& &1.student_id == student_id)
  end
end