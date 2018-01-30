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

  # @new_class_status 100
  @syllabus_status 200
  @weight_status 300
  @assignment_status 400
  @review_status 500
  @help_status 600
  @complete_status 700
  @change_status 800

  @weight_lock 100
  @assignment_lock 200
  @review_lock 300

  # A new class has been created by a student.
  # def check_status(%Class{class_status_id: nil} = class, %{params: %{is_student: true}}) do
  #   class |> set_status(@new_class_status)
  # end
  # A new class has been added, and it is a class that will never have a syllabus.
  def check_status(%Class{class_status_id: nil, is_syllabus: false} = class, _params) do
    class |> set_status(@weight_status)
  end
  # A new class has been added.
  def check_status(%Class{class_status_id: nil} = class, _params) do
    class |> set_status(@syllabus_status)
  end
  # A syllabus has been added to a class that needs a syllabus.
  def check_status(%Class{class_status_id: @syllabus_status} = class, %{doc: %{is_syllabus: true} = doc}) do
    case doc.class_id == class.id do
      true -> class |> set_status(@weight_status)
      false -> {:error, %{class_id: "Class and doc do not match"}}
    end
  end
  # A class in the change status has a change request completed.
  def check_status(%Class{class_status_id: @change_status} = class, %{change_request: %{is_completed: true} = change_request}) do
    case change_request.class_id == class.id do
      true -> check_req_status(class)
      false -> {:error, %{class_id: "Class and change request do not match"}}
    end
  end
  # A class in the change status has a student request completed.
  def check_status(%Class{class_status_id: @change_status} = class, %{student_request: %{is_completed: true} = student_request}) do
    case student_request.class_id == class.id do
      true -> check_req_status(class)
      false -> {:error, %{class_id: "Class and student request do not match"}}
    end
  end
  # A class has a change request created.
  def check_status(%Class{} = class, %{change_request: %{is_completed: false} = change_request}) do
    case change_request.class_id == class.id do
      true -> class |> Repo.preload(:class_status) |> change_status_check()
      false -> {:error, %{class_id: "Class and change request do not match"}}
    end
  end
  # A class has a help request created.
  def check_status(%Class{} = class, %{help_request: %{is_completed: false} = help_request}) do
    case help_request.class_id == class.id do
      true -> class |> Repo.preload(:class_status) |> help_status_check()
      false -> {:error, %{class_id: "Class and change request do not match"}}
    end
  end
  # A class has been fully unlocked. Get the highest lock
  def check_status(%Class{} = class, %{unlock: unlock}) when is_list(unlock) do
    max_lock = unlock
    |> Enum.filter(& &1.is_completed and &1.class_id == class.id)
    |> Enum.reduce(0, &case &1 > &2 do
        true -> &1
        false -> &2
      end)
    case max_lock do
      @review_lock -> class |> set_status(@complete_status)
      @assignment_lock -> class |> set_status(@complete_status)
      @weight_lock -> class |> set_status(@assignment_lock)
      _ -> {:ok, nil}
    end
  end
  # A class has been unlocked in the weights status.
  def check_status(%Class{class_status_id: @weight_status} = class, %{unlock: %{class_lock_section_id: @weight_lock, is_completed: true} = unlock}) do
    case unlock.class_id == class.id do
      true -> class |> set_status(@assignment_status)
      false -> {:error, %{class_id: "Class and lock do not match"}}
    end
  end
  # A class has been unlocked in the assignments status.
  def check_status(%Class{class_status_id: @assignment_status} = class, %{unlock: %{class_lock_section_id: @assignment_lock, is_completed: true} = unlock}) do
    case unlock.class_id == class.id do
      true -> class |> set_status(@review_status)
      false -> {:error, %{class_id: "Class and lock do not match"}}
    end
  end
  # A class has been unlocked from the review status.
  def check_status(%Class{class_status_id: @review_status} = class, %{unlock: %{class_lock_section_id: @review_lock, is_completed: true} = unlock}) do
    case unlock.class_id == class.id do
      true -> class |> set_status(@complete_status)
      false -> {:error, %{class_id: "Class and lock do not match"}}
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

  defp help_status_check(%{class_status: %{is_complete: true}}) do
    {:error, %{error: "Class is complete, use Change Request."}}
  end
  defp help_status_check(%{class_status: %{is_complete: false}} = class) do
    class |> set_status(@help_status)
  end
end