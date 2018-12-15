defmodule Skoller.Chats.Classes do
  @moduledoc """
  A context module for chat classes
  """

  alias Skoller.Classes
  alias Skoller.Chats.Schools

  @doc """
  Gets if a class has chat enabled.

  Returns a boolean
  """
  def check_class_chat_enabled(class_id) do
    class = Classes.get_class_by_id(class_id)
    case class |> check_class() do
      true -> class.class_period_id |> Schools.check_school_chat_enabled_by_period()
      resp -> resp
    end
  end

  defp check_class(%{is_chat_enabled: true}), do: true
  defp check_class(_class), do: false
end