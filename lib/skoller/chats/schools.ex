defmodule Skoller.Chats.Schools do
  @moduledoc """
  A context module for chat in schools
  """

  alias Skoller.Schools

  @doc """
  Checks if a school's chat is enabled by the class period id

  Returns a boolean.
  """
  def check_school_chat_enabled_by_period(class_period_id) do
    Schools.get_school_from_period(class_period_id)
    |> check_school()
  end

  defp check_school(%{is_chat_enabled: true}), do: true
  defp check_school(_school), do: false
end