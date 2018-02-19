defmodule ClassnavapiWeb.Helpers.ChatHelper do
  def is_liked([]), do: false
  def is_liked(enum, student_id) do
    require Logger
    t = enum |> Enum.any?(& &1.student_id == student_id)
    Logger.info(t)
    t
  end
end