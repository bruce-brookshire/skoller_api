defmodule ClassnavapiWeb.Helpers.StatusHelper do

  alias Classnavapi.Repo

  @moduledoc """
  
  Manages class statuses.

  All check_status/2 return either {:ok, value} or {:error, value}

  check_changeset_status/2 takes a changeset and params and returns a changeset.

  """

  @new_class_status 100
  @syllabus_status 200
  @weight_status 300

  def check_status(%{student_class: %{class_id: class_id}}, %{is_ghost: true, id: id} = class) do
    case class_id == id do
      true -> remove_ghost(class)
      false -> {:error, %{class_id: "Class id enrolled into does not match"}}
    end
  end
  def check_status(%{}, %{is_ghost: false}), do: {:ok, nil}

  def check_changeset_status(changeset, %{} = params) do
    changeset
    |> check_new_class(params)
    |> check_needs_syllabus(params)
    |> check_needs_weight(params)
  end

  defp check_new_class(%Ecto.Changeset{changes: %{class_status_id: _}} = changeset, %{}), do: changeset
  defp check_new_class(changeset, %{"is_student" => true}) do
    changeset |> Ecto.Changeset.change(%{class_status_id: @new_class_status})
  end
  defp check_new_class(changeset, %{}), do: changeset

  defp check_needs_syllabus(%Ecto.Changeset{changes: %{class_status_id: _}} = changeset, %{}), do: changeset
  defp check_needs_syllabus(changeset, %{"is_syllabus" => true}) do
    changeset |> Ecto.Changeset.change(%{class_status_id: @syllabus_status})
  end
  defp check_needs_syllabus(changeset, %{}), do: changeset

  defp check_needs_weight(%Ecto.Changeset{changes: %{class_status_id: _}} = changeset, %{}), do: changeset
  defp check_needs_weight(changeset, %{"is_syllabus" => false}) do
    changeset |> Ecto.Changeset.change(%{class_status_id: @weight_status})
  end
  defp check_needs_weight(changeset, %{}), do: changeset

  defp remove_ghost(%{} = params) do
    params
    |> Ecto.Changeset.change(%{is_ghost: false})
    |> Repo.update()
  end
end