defmodule ClassnavapiWeb.Helpers.ViewCalcs do

  @moduledoc """
  
  Calcs for views.

  """

  @ghost_status "Ghost"

  defp compare_classes(true, true), do: "Full Term"
  defp compare_classes(true, false), do: "1st Half"
  defp compare_classes(false, true), do: "2nd Half"
  defp compare_classes(false, false), do: "Custom"

  def get_class_length(class, class_period) do
      compare_classes(class.class_start == class_period.start_date, class.class_end == class_period.end_date)
  end

  def get_status(%{class_status: %{is_complete: false}, is_ghost: true}), do: @ghost_status
  def get_status(%{class_status: status}), do: status.name
end
  