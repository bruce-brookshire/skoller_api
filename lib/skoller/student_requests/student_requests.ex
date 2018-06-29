defmodule Skoller.StudentRequests do
  @moduledoc """
  A context module for student requests.
  """

  alias Skoller.Repo
  alias Skoller.Class.StudentRequest
  alias Skoller.ClassDocs
  alias Skoller.Classes
  alias Skoller.MapErrors
  alias Skoller.Class.StudentRequest.Doc

  @syllabus_request 100

  @doc """
  Creates a student request.

  If files are included in the params, files will be added to the class.

  ## Returns
  `{:ok, Map}` or `{:error, _, _, _}` where `Map` has the following
   * `{:student_request, Skoller.Class.StudentRequest}`
   * `{:doc_upload, Skoller.Class.StudentRequest.Doc}`
   * `{:status, Skoller.Classes.check_status/2}`
  """
  def create(user, class_id, params) do
    changeset = StudentRequest.changeset(%StudentRequest{}, params)
    
    class = Classes.get_class_by_id!(class_id)
    
    Ecto.Multi.new
    |> Ecto.Multi.insert(:student_request, changeset)
    |> Ecto.Multi.run(:doc_upload, &upload_class_docs(user, params, &1.student_request))
    |> Ecto.Multi.run(:status, &Classes.check_status(class, &1))
    |> Repo.transaction()
  end

  @doc """
  Completes a student request.

  May change the class status.

  ## Returns
  `{:ok, Map}` or `{:error, _, _, _}` where map contains
   * `{:student_request, Skoller.Class.StudentRequest}`
   * `{:class_status, Skoller.Classes.check_status/2}`
  """
  def complete(request_id) do
    student_request_old = Repo.get!(StudentRequest, request_id)

    changeset = StudentRequest.changeset(student_request_old, %{is_completed: true})

    class = Classes.get_class_by_id(student_request_old.class_id)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:student_request, changeset)
    |> Ecto.Multi.run(:class_status, &Classes.check_status(class, &1))
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
end