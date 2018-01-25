defmodule ClassnavapiWeb.Api.V1.Class.StudentRequestController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Repo
  alias Classnavapi.Class.StudentRequest
  alias ClassnavapiWeb.Helpers.ClassDocUpload
  alias Classnavapi.Class.Doc
  alias ClassnavapiWeb.Helpers.RepoHelper
  alias Classnavapi.Class

  import ClassnavapiWeb.Helpers.AuthPlug

  @student_role 100
  @admin_role 200

  @syllabus_request 100

  @help_status 600
  @change_status 800

  plug :verify_role, %{roles: [@student_role, @admin_role]}
  plug :verify_member, :class

  def create(%{assigns: %{user: user}} = conn, %{} = params) do

    changeset = StudentRequest.changeset(%StudentRequest{}, params)
    
    multi = Ecto.Multi.new
    |> Ecto.Multi.insert(:student_request, changeset)
    |> Ecto.Multi.run(:doc_upload, &upload_class_docs(user, params, &1.student_request))
    |> Ecto.Multi.run(:status, &update_class_status(&1.student_request))

    case Repo.transaction(multi) do
      {:ok, %{class: class}} ->
        render(conn, ClassView, "show.json", class: class)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  defp update_class_status(%{class_id: class_id}) do
    class = Repo.get!(Class, class_id)
    |> Repo.preload(:class_status)

    changeset = case class.class_status.is_complete do
      false -> Ecto.Changeset.change(class, %{class_status_id: @help_status})
      true -> Ecto.Changeset.change(class, %{class_status_id: @change_status})
    end

    Repo.update(changeset)
  end

  defp upload_class_docs(user, %{"files" => files} = params, student_request) do 
    status = files |> Enum.map(&upload_class_doc(user, &1, params, student_request))
    status |> Enum.find({:ok, status}, &RepoHelper.errors(&1))
  end
  defp upload_class_docs(_user, _params, _student_request), do: {:ok, nil}

  defp upload_class_doc(user, file, %{"class_id" => class_id}, student_request) do 
    location = ClassDocUpload.upload_class_doc(file)

    params = %{} 
    |> Map.put("path", location)
    |> Map.put("name", file.filename)
    |> Map.put("user_id", user.id)
    |> Map.put("is_syllabus", get_is_syllabus(student_request))
    |> Map.put("class_id", class_id)

    doc = Doc.changeset(%Doc{}, params)
    |> Repo.insert()

    Repo.insert(%StudentRequest.Doc{doc_id: doc.id, class_student_request_id: student_request.id})
  end

  defp get_is_syllabus(%{class_student_request_type_id: @syllabus_request}), do: true
  defp get_is_syllabus(_params), do: false
end