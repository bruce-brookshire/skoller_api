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
  alias Skoller.StudentRequests.Type

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
    |> Ecto.Multi.run(:doc_upload, fn (_, changes) -> upload_class_docs(user, params, changes.student_request) end)
    |> Ecto.Multi.run(:doc_removal, fn (_, changes) -> remove_docs_from_same_uploader(changes, class) end)
    |> Ecto.Multi.run(:status, fn (_, changes) -> ClassStatuses.check_status(class, changes) end)
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
    |> Ecto.Multi.run(:class_status, fn (_, changes) -> ClassStatuses.check_status(class, changes) end)
    |> Repo.transaction()
  end

  @doc """
  Gets a list of student request types
  """
  def get_student_request_types() do
    Repo.all(Type)
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
    {:ok, %{doc: doc}} = ClassDocs.upload_doc(file, user.id, class_id, get_is_syllabus(student_request))
    Repo.insert(%Doc{doc_id: doc.id, class_student_request_id: student_request.id})
  end

  defp get_is_syllabus(%{class_student_request_type_id: @syllabus_request}), do: true
  defp get_is_syllabus(_params), do: false

  defp complete_by_class_status(changeset, %{class_status: %{is_complete: false}}), do: changeset |> Ecto.Changeset.change(%{is_completed: true})
  defp complete_by_class_status(changeset, _class), do: changeset

  defp remove_docs_from_same_uploader(%{student_request: %{user_id: nil}}, _class), do: {:ok, nil}
  defp remove_docs_from_same_uploader(%{student_request: %{user_id: user_id, class_student_request_type_id: @syllabus_request}, doc_upload: upload}, class) when not is_nil(upload) do
    class = class |> Repo.preload(:docs)
    IO.inspect(upload)
    doc_ids = class.docs
    |> Enum.filter(&user_id == &1.user_id and &1.is_syllabus == true and &1.id != upload[:ok].doc_id)
    |> Enum.map(fn d -> d.id end)
    {num_deleted, _return} = ClassDocs.delete_docs(doc_ids)
    IO.inspect(num_deleted)
    IO.inspect(doc_ids)
    {:ok, num_deleted}
  end
  defp remove_docs_from_same_uploader(request, _class) do
    {:ok, nil}
  end
end