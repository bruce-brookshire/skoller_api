defmodule ClassnavapiWeb.Helpers.StatusHelper do

  alias Classnavapi.Repo

  @moduledoc """
  
  Manages class statuses.

  All functions return either {:ok, value} or {:error, value}

  """

  def check_status(%{student_class: %{class_id: class_id}}, %{is_ghost: true, id: id} = class) do
    case class_id == id do
      true -> remove_ghost(class)
      false -> {:error, %{class_id: "Class id enrolled into does not match"}}
    end
  end
  def check_status(%{}, %{is_ghost: false}), do: {:ok, nil}

  defp remove_ghost(%{} = params) do
    params
    |> Ecto.Changeset.change(%{is_ghost: false})
    |> Repo.update()
  end
end