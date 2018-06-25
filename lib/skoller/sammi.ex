defmodule Skoller.Sammi do
  @moduledoc """
  The context module for Sammi
  """

  alias Skoller.Professors
  alias Skoller.Repo
  alias Skoller.Classes

  require Logger

  @doc """
  Uses Sammi to extract syllabus info and set professor and grade scale info.

  ## Notes
   * Only runs if `%{"is_syllabus" => "true"}` is part of `params`
   * Due to long run time, this should be set as a `Task`

  ## Returns
  `:ok` or `:error`
  """
  def sammi(params, file)
  def sammi(_params, nil), do: nil
  def sammi(%{"is_syllabus" => "true", "class_id" => class_id}, file) do
    case Sammi.Api.extract(file) do
      {:ok, sammi} ->
        Logger.info(inspect(sammi))
        sammi |> add_grade_scale(class_id)
        sammi |> add_professor_info(class_id)
        :ok
      {:error, val} ->
        val
        |> inspect()
        |> Logger.error()
        :error
    end
  end
  def sammi(_params, _file), do: nil

  defp add_grade_scale(%{"grade_scale" => %{"values" => %{}}}, _class_id), do: nil
  defp add_grade_scale(%{"grade_scale" => %{"values" => val}}, class_id) do
    val = val |> String.trim()
    class_id
    |> Classes.get_class_by_id!()
    |> Classes.update_class(%{"grade_scale" => val})
  end

  defp add_professor_info(%{"professor_info" => professor_info}, class_id) do
    class = Classes.get_class_by_id!(class_id)
            |> Repo.preload(:professor)
    case class.professor do
      nil -> nil
      professor -> 
        professor_info 
        |> extract_professor_details(professor)
        |> update_professor(professor)
    end
  end

  defp extract_professor_details(professor_info, professor) do
    Map.new()
    |> get_office_hours(professor_info, professor)
    |> get_office_location(professor_info, professor)
    |> get_phone(professor_info, professor)
    |> get_email(professor_info, professor)
  end

  defp get_office_hours(map, %{"office_hours" => ""}, %{office_availability: nil}), do: map |> Map.put("office_availability", nil)
  defp get_office_hours(map, %{"office_hours" => val}, %{office_availability: nil}) do 
    val = val |> String.trim()
    map |> Map.put("office_availability", val)
  end
  defp get_office_hours(map, _params, %{office_availability: _val}), do: map

  defp get_office_location(map, %{"office_location" => ""}, %{office_location: nil}), do: map |> Map.put("office_location", nil)
  defp get_office_location(map, %{"office_location" => val}, %{office_location: nil}) do 
    val = val |> String.trim()
    map |> Map.put("office_location", val)
  end
  defp get_office_location(map, _params, %{office_location: _val}), do: map

  defp get_phone(map, %{"phone" => ""}, %{phone: nil}), do: map |> Map.put("phone", nil)
  defp get_phone(map, %{"phone" => val}, %{phone: nil}) do
    val = val |> String.trim()
    case val |> String.match?(~r/^([0-9]{3}-)?[0-9]{3}-[0-9]{4}$/) do
      true -> map |> Map.put("phone", val)
      false -> map |> Map.put("phone", nil)
    end
  end
  defp get_phone(map, _params, %{phone: _val}), do: map

  defp get_email(map, %{"email" => ""}, %{email: nil}), do: map |> Map.put("email", nil)
  defp get_email(map, %{"email" => val}, %{email: nil}) do
    val = val |> String.trim()
    case val |> String.match?(~r/.{2,}@/) do
      true -> map |> Map.put("email", val)
      false -> map |> Map.put("email", nil)
    end
  end
  defp get_email(map, _params, %{email: _val}), do: map

  defp update_professor(params, professor) do
    Professors.update_professor(professor, params)
  end
end