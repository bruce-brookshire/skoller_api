defmodule ClassnavapiWeb.Api.V1.Class.DocController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Class
  alias Classnavapi.Class.Doc
  alias Classnavapi.Professor
  alias Classnavapi.Repo
  alias ClassnavapiWeb.Class.DocView
  alias Classnavapi.DocUpload
  alias ClassnavapiWeb.ChangesetView
  alias Ecto.UUID
  alias ClassnavapiWeb.Helpers.StatusHelper

  import Ecto.Query
  import ClassnavapiWeb.Helpers.AuthPlug
  
  @student_role 100
  @admin_role 200
  @syllabus_worker_role 300
  
  plug :verify_role, %{roles: [@student_role, @admin_role, @syllabus_worker_role]}
  plug :verify_member, :class

  def create(conn, %{"file" => file, "class_id" => class_id} = params) do

    {sammi, _code} = get_sammi_data(params)

    decoded_sammi = sammi
    |> String.replace("'", ~s("))
    |> Poison.decode!

    decoded_sammi |> add_grade_scale(class_id)
    decoded_sammi |> add_professor_info(class_id)

    scope = %{"id" => UUID.generate()}
    location = 
      case DocUpload.store({file, scope}) do
        {:ok, inserted} ->
          DocUpload.url({inserted, scope})
        _ ->
          nil
      end

    params = params 
    |> Map.put("path", location)
    |> Map.put("name", file.filename)

    changeset = Doc.changeset(%Doc{}, params)

    class = Repo.get!(Class, class_id)

    multi = Ecto.Multi.new
    |> Ecto.Multi.insert(:doc, changeset)
    |> Ecto.Multi.run(:status, &StatusHelper.check_status(&1, class))

    case Repo.transaction(multi) do
      {:ok, %{doc: doc}} ->
        render(conn, DocView, "show.json", doc: doc)
      {:error, _, failed_value, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ChangesetView, "error.json", changeset: failed_value)
    end
  end

  def index(conn, %{"class_id" => class_id}) do
    docs = Repo.all(from docs in Doc, where: docs.class_id == ^class_id)
    render(conn, DocView, "index.json", docs: docs)
  end

  defp add_grade_scale(%{"grade_scale" => %{"grade_scale" => %{"value" => ""}}}, _class_id), do: nil
  defp add_grade_scale(%{"grade_scale" => %{"grade_scale" => %{"value" => val}}}, class_id) do
    class = Repo.get!(Class, class_id)
    Class.changeset_update(class, %{"grade_scale" => val})
    |> Repo.update()
  end

  defp add_professor_info(%{"professor_info" => professor_info}, class_id) do
    class = Repo.get!(Class, class_id)
            |> Repo.preload(:professor)
    professor_params = professor_info |> extract_professor_details()
    case class.professor do
      nil -> nil
        # professor_params 
        # |> find_professor(class)
        # |> process_professor()
      professor -> 
        professor_params 
        |> update_professor(professor)
    end
  end

  defp update_professor(params, professor) do
    params = params |> Map.delete("name_first")
    |> Map.delete("name_last")
    Professor.changeset_update(professor, params)
    |> Repo.update()
  end

  defp extract_professor_details(professor_info) do
    Map.new()
    |> get_name(professor_info)
    |> get_office_hours(professor_info)
    |> get_office_location(professor_info)
    |> get_phone(professor_info)
  end

  defp get_name(map, %{"name" => %{"value" => ""}}), do: map |> Map.put("name", nil)
  defp get_name(map, %{"name" => %{"value" => val}}) do 
    name = val 
    |> String.trim()
    |> String.split()

    name_last = name
    |> List.last()

    name_first = name
    |> List.delete_at(-1)
    |> Enum.reduce("", & &2 <> " " <> &1)
    |> String.trim()

    map |> Map.put("name_first", name_first)
    |> Map.put("name_last", name_last)
  end

  defp get_office_hours(map, %{"office_hours" => %{"value" => ""}}), do: map |> Map.put("office_availability", nil)
  defp get_office_hours(map, %{"office_hours" => %{"value" => val}}) do 
    val = val |> String.trim()
    map |> Map.put("office_availability", val)
  end

  defp get_office_location(map, %{"office_location" => %{"value" => ""}}), do: map |> Map.put("office_location", nil)
  defp get_office_location(map, %{"office_location" => %{"value" => val}}) do 
    val = val |> String.trim()
    map |> Map.put("office_location", val)
  end

  defp get_phone(map, %{"phone" => %{"value" => ""}}), do: map |> Map.put("phone", nil)
  defp get_phone(map, %{"phone" => %{"value" => val}}) do
    val = val |> String.trim()
    map |> Map.put("phone", val)
  end

  defp get_sammi_data(%{"file" => file, "is_syllabus" => "true"}) do
    System.cmd("python3", ["./classifiers/sammi/main.py", "extract", file.path], cd: "./priv/sammi")
  end
  defp get_sammi_data(_params), do: nil
end