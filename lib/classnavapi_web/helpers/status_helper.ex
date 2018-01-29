defmodule ClassnavapiWeb.Helpers.StatusHelper do

  alias Classnavapi.Repo
  alias Classnavapi.Class.StudentRequest
  alias Classnavapi.Class
  alias Classnavapi.Class.ChangeRequest

  import Ecto.Query

  @moduledoc """
  
  Manages class statuses.

  All check_status/2 return either {:ok, value} or {:error, value}

  check_changeset_status/2 takes a changeset and params and returns a changeset.

  """

  @new_class_status 100
  @syllabus_status 200
  @weight_status 300
  @assignment_status 400
  @review_status 500
  @help_status 600
  @complete_status 700
  @change_status 800

  @weight_lock 100
  @assignment_lock 200

  # def check_status(%Class{class_status_id: nil} = class, %{params: %{is_student: true}}) do
  #   class |> set_status(@new_class_status)
  # end
  def check_status(%Class{class_status_id: nil, is_syllabus: false} = class, _params) do
    class |> set_status(@weight_status)
  end
  def check_status(%Class{class_status_id: nil} = class, _params) do
    class |> set_status(@syllabus_status)
  end
  def check_status(%Class{class_status_id: @syllabus_status} = class, %{doc: %{is_syllabus: true} = doc}) do
    case doc.class_id == class.id do
      true -> class |> set_status(@weight_status)
      false -> {:error, %{class_id: "Class and doc not match"}}
    end
  end
  def check_status(%Class{class_status_id: @change_status} = class, %{change_request: %{is_completed: true} = change_request}) do
    case change_request.class_id == class.id do
      true -> check_req_status(class)
      false -> {:error, %{class_id: "Class and change request not match"}}
    end
  end
  def check_status(%Class{} = class, %{change_request: %{is_completed: false} = change_request}) do
    case change_request.class_id == class.id do
      true -> class |> Repo.preload(:class_status) |> change_status_check()
      false -> {:error, %{class_id: "Class and change request not match"}}
    end
  end
  def check_status(%Class{class_status_id: @change_status} = class, %{student_request: %{is_completed: true} = student_request}) do
    case student_request.class_id == class.id do
      true -> check_req_status(class)
      false -> {:error, %{class_id: "Class and student request not match"}}
    end
  end
  def check_status(_class, _params), do: {:ok, nil}

  defp set_status(class, status) do
    Ecto.Changeset.change(class, %{class_status_id: status})
    |> Repo.update()
  end

  def check_status(%{student_class: %{class_id: class_id}}, %{is_ghost: true, id: id} = class) do
    case class_id == id do
      true -> remove_ghost(class)
      false -> {:error, %{class_id: "Class id enrolled into does not match"}}
    end
  end
  def check_status(%{}, %{}), do: {:ok, nil}

  def set_help_status(%{help_request: %{class_id: class_id}}, %{id: id} = class) do
    case class_id == id do
      true -> help_status_check(class)
      false -> {:error, %{class_id: "Class and issue do not match."}}
    end
  end

  def unlock_class(%Ecto.Changeset{data: %{class_status_id: @weight_status}} = changeset, %{} = params) do
    changeset
    |> check_needs_assignments(params)
    |> check_needs_complete(params)
  end
  def unlock_class(%Ecto.Changeset{data: %{class_status_id: @assignment_status}} = changeset, %{} = params) do
    changeset
    |> check_needs_review(params)
    |> check_needs_complete(params)
  end
  def unlock_class(%Ecto.Changeset{data: %{class_status_id: @review_status}} = changeset, %{} = params) do
    changeset
    |> check_needs_complete(params)
  end
  def unlock_class(%Ecto.Changeset{data: %{class_status_id: _}} = changeset, %{}), do: changeset

  defp check_req_status(%{class_id: class_id} = class) do
    cr_query = from(cr in ChangeRequest)
    |> where([cr], cr.class_id == ^class_id and cr.is_completed == false)
    |> Repo.all()

    sr_query = from(sr in StudentRequest)
    |> where([sr], sr.class_id == ^class_id and sr.is_completed == false)
    |> Repo.all()

    results = cr_query ++ sr_query

    case results do
      [] -> 
        class |> set_status(@complete_status)
      _results -> 
        {:ok, nil}
    end
  end

  # defp check_new_class(%Ecto.Changeset{changes: %{class_status_id: _}} = changeset, %{}), do: changeset
  # defp check_new_class(changeset, %{"is_student" => true}) do
  #   changeset |> change_changeset_status(@new_class_status)
  # end
  # defp check_new_class(changeset, %{}), do: changeset

  defp check_needs_assignments(%Ecto.Changeset{changes: %{class_status_id: _}} = changeset, %{}), do: changeset
  defp check_needs_assignments(changeset, %{"class_lock_section_id" => @weight_lock, "is_completed" => true}) do
    case changeset.changes |> Map.equal?(%{}) do
      true -> changeset |> change_changeset_status(@assignment_status)
      false -> changeset
    end
  end
  defp check_needs_assignments(changeset, %{}), do: changeset

  defp check_needs_review(%Ecto.Changeset{changes: %{class_status_id: _}} = changeset, %{}), do: changeset
  defp check_needs_review(changeset, %{"class_lock_section_id" => @assignment_lock, "is_completed" => true}) do
    changeset |> change_changeset_status(@review_status)
  end
  defp check_needs_review(changeset, %{}), do: changeset

  defp check_needs_complete(%Ecto.Changeset{changes: %{class_status_id: _}} = changeset, %{}), do: changeset
  defp check_needs_complete(changeset, %{"is_completed" => true}) do
    changeset |> change_changeset_status(@complete_status)
  end
  defp check_needs_complete(changeset, %{}), do: changeset

  defp change_changeset_status(changeset, new_status) do
    changeset |> Ecto.Changeset.change(%{class_status_id: new_status})
  end

  defp remove_ghost(%{} = params) do
    params
    |> Ecto.Changeset.change(%{is_ghost: false})
    |> Repo.update()
  end

  defp change_status_check(%{class_status: %{is_complete: false}}) do
    {:error, %{error: "Class is incomplete, use Help Request."}}
  end
  defp change_status_check(%{class_status: %{is_complete: true}} = class) do
    class |> set_status(@change_status)
  end
  defp change_status_check(%{}), do: {:ok, nil}

  defp help_status_check(%{class_status: %{is_complete: true}}) do
    {:error, %{error: "Class is complete, use Change Request."}}
  end
  defp help_status_check(%{class_status: %{is_complete: false}} = params) do
    params
    |> Ecto.Changeset.change(%{class_status_id: @help_status})
    |> Repo.update()
  end
  defp help_status_check(%{}), do: {:ok, nil}
end