defmodule ClassnavapiWeb.Helpers.ViewCalcs do

  @moduledoc """
  
  Calcs for views.

  """

  defp compare_classes(true, true), do: "Full Term"
  defp compare_classes(true, false), do: "1st Half"
  defp compare_classes(false, true), do: "2nd Half"
  defp compare_classes(false, false), do: "Custom"

  def get_class_length(class, class_period) do
      compare_classes(class.class_start == class_period.start_date, class.class_end == class_period.end_date)
  end
end
  