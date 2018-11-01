defmodule Skoller.StudentRequests do
  @moduledoc """
  A context module for student requests.
  """

  alias Skoller.Repo
  alias Skoller.StudentRequests.StudentRequest
  alias Skoller.ClassDocs
  alias Skoller.Classes
  alias Skoller.MapErrors
  alias Skoller.StudentRequests.Doc
  alias Skoller.ClassStatuses.Classes, as: ClassStatuses

  @syllabus_request 100

  @doc """
  Creates a student request.

  If files are included in the params, files will be added to the class.

  ## Returns
  `{:ok, Map}` or `{:error, _, _, _}` where `Map` has the following
   * `{:student_request, Skoller.StudentRequests.StudentRequest}`
   * `{:doc_upload, Skoller.StudentRequests.Doc}`
   * `{:status, Skoller.ClassStatuses.Classes.check_status/2}`
  """
  def create(user, class_id, params) do
    class = Classes.get_class_by_id!(class_id) |> Repo.preload(:class_status)

    changeset = StudentRequest.changeset(%StudentRequest{}, params)
    |> complete_by_class_status(class)

    Ecto.Multi.new
    |> Ecto.Multi.insert(:student_request, changeset)
    |> Ecto.Multi.run(:doc_upload, &upload_class_docs(user, params, &1.student_request))
    |> Ecto.Multi.run(:doc_removal, &remove_docs_from_same_uploader(&1, class))
    |> Ecto.Multi.run(:status, &ClassStatuses.check_status(class, &1))
    |> Repo.transaction()
  end

  @doc """
  Completes a student request.

  May change the class status.

  ## Returns
  `{:ok, Map}` or `{:error, _, _, _}` where map contains
   * `{:student_request, Skoller.StudentRequests.StudentRequest}`
   * `{:class_status, Skoller.ClassStatuses.Classes.check_status/2}`
  """
  def complete_student_request(request_id) do
    student_request_old = Repo.get!(StudentRequest, request_id)

    changeset = StudentRequest.changeset(student_request_old, %{is_completed: true})

    class = Classes.get_class_by_id(student_request_old.class_id)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:student_request, changeset)
    |> Ecto.Multi.run(:class_status, &ClassStatuses.check_status(class, &1))
    |> Repo.transaction()
  end

  defp upload_class_docs(user, %{"files" => files} = params, student_request) do 
    status = files |> Enum.map(&upload_class_doc(user, &1, params, student_request))
    status |> Enum.find({:ok, status}, &MapErrors.check_tuple(&1))
  end
  defp upload_class_docs(_user, _params, _student_request), do: {:ok, nil}

  defp upload_class_doc(user, {_num, file}, params, student_request) do 
    upload_class_doc(user, file, params, student_request)
  end

  defp upload_class_doc(user, file, %{"class_id" => class_id}, student_request) do 
    location = ClassDocs.upload_class_doc(file)

    {:ok, doc} = %{} 
    |> Map.put("path", location)
    |> Map.put("name", file.filename)
    |> Map.put("user_id", user.id)
    |> Map.put("is_syllabus", get_is_syllabus(student_request))
    |> Map.put("class_id", class_id)
    |> ClassDocs.insert()

    Repo.insert(%Doc{doc_id: doc.id, class_student_request_id: student_request.id})
  end

  defp get_is_syllabus(%{class_student_request_type_id: @syllabus_request}), do: true
  defp get_is_syllabus(_params), do: false

  defp complete_by_class_status(changeset, %{class_status: %{is_complete: false}}), do: changeset |> Ecto.Changeset.change(%{is_completed: true})
  defp complete_by_class_status(changeset, _class), do: changeset

  defp remove_docs_from_same_uploader(%{student_request: %{user_id: nil}}, _class), do: {:ok, nil}
  defp remove_docs_from_same_uploader(%{student_request: %{user_id: user_id, class_student_request_type_id: @syllabus_request}, doc_upload: upload}, class) when not is_nil(upload) do
    class = class |> Repo.preload(:docs)
    class.docs
    |> Enum.filter(&user_id == &1.user_id and &1.is_syllabus == true)
    |> Repo.delete_all()
  end
end