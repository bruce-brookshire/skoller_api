defmodule SkollerWeb.Api.V1.Class.StudentRequestController do
  use SkollerWeb, :controller

  alias Skoller.Repo
  alias Skoller.Class.StudentRequest
  alias SkollerWeb.Helpers.ClassDocUpload
  alias Skoller.Class.Doc
  alias SkollerWeb.Helpers.RepoHelper
  alias SkollerWeb.Helpers.StatusHelper
  alias Skoller.Schools.Class
  alias SkollerWeb.Class.StudentRequestView

  import SkollerWeb.Helpers.AuthPlug

  @student_role 100
  @admin_role 200

  @syllabus_request 100

  plug :verify_role, %{roles: [@student_role, @admin_role]}
  plug :verify_member, :class

  def create(%{assigns: %{user: user}} = conn, %{} = params) do

    params = params |> Map.put("user_id", conn.assigns[:user].id)
    
    changeset = StudentRequest.changeset(%StudentRequest{}, params)

    class = Repo.get!(Class, params["class_id"])
    
    multi = Ecto.Multi.new
    |> Ecto.Multi.insert(:student_request, changeset)
    |> Ecto.Multi.run(:doc_upload, &upload_class_docs(user, params, &1.student_request))
    |> Ecto.Multi.run(:status, &StatusHelper.check_status(class, &1))

    case Repo.transaction(multi) do
      {:ok, %{student_request: student_request}} ->
        render(conn, StudentRequestView, "show.json", student_request: student_request)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  defp upload_class_docs(user, %{"files" => files} = params, student_request) do 
    status = files |> Enum.map(&upload_class_doc(user, &1, params, student_request))
    status |> Enum.find({:ok, status}, &RepoHelper.errors(&1))
  end
  defp upload_class_docs(_user, _params, _student_request), do: {:ok, nil}

  defp upload_class_doc(user, {_num, file}, params, student_request) do 
    upload_class_doc(user, file, params, student_request)
  end

  defp upload_class_doc(user, file, %{"class_id" => class_id}, student_request) do 
    location = ClassDocUpload.upload_class_doc(file)

    params = %{} 
    |> Map.put("path", location)
    |> Map.put("name", file.filename)
    |> Map.put("user_id", user.id)
    |> Map.put("is_syllabus", get_is_syllabus(student_request))
    |> Map.put("class_id", class_id)

    {:ok, doc} = Doc.changeset(%Doc{}, params)
    |> Repo.insert()

    Repo.insert(%StudentRequest.Doc{doc_id: doc.id, class_student_request_id: student_request.id})
  end

  defp get_is_syllabus(%{class_student_request_type_id: @syllabus_request}), do: true
  defp get_is_syllabus(_params), do: false
end