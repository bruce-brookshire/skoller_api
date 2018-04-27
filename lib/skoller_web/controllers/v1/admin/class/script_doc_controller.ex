defmodule SkollerWeb.Api.V1.Admin.Class.ScriptDocController do
  use SkollerWeb, :controller

  alias Skoller.Class.Doc
  alias Skoller.Repo
  alias SkollerWeb.Class.DocView
  alias Skoller.DocUpload
  alias Ecto.UUID
  alias SkollerWeb.Helpers.RepoHelper
  alias Skoller.Classes
  alias Skoller.Universities
  alias Skoller.Professors

  import SkollerWeb.Helpers.AuthPlug

  require Logger
  
  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

  def create(%{assigns: %{user: user}} = conn, %{"file" => file} = params) do

    classes = params |> get_class_from_hash()

    classes |> Enum.each(&sammi(&1, params))

    location = file |> upload_file()

    params = params 
    |> Map.put("path", location)
    |> Map.put("name", file.filename)
    |> Map.put("is_syllabus", true)
    |> Map.put("user_id", user.id)

    multi = Ecto.Multi.new
    |> Ecto.Multi.run(:doc, &insert_class_doc(classes, params, &1))
    |> Ecto.Multi.run(:status, &check_statuses(classes, &1.doc))

    case Repo.transaction(multi) do
      {:ok, %{doc: doc}} ->
        render(conn, DocView, "index.json", docs: doc)
      {:error, _, failed_value, _} ->
        conn
        |> RepoHelper.multi_error(failed_value)
    end
  end

  defp check_statuses(classes, docs) do
    status = classes |> Enum.map(&Classes.check_status(&1, %{doc: elem(docs |> Enum.find(fn(x) -> elem(x, 1).class_id == &1.id end), 1)}))
    status |> Enum.find({:ok, status}, &RepoHelper.errors(&1))
  end

  defp insert_class_doc(classes, params, _) do
    status = classes |> Enum.map(&insert_doc(&1, params))
    status |> Enum.find({:ok, status}, &RepoHelper.errors(&1))
  end

  defp insert_doc(class, params) do
    params = params 
    |> Map.put("class_id", class.id)

    changeset = Doc.changeset(%Doc{}, params)

    Repo.insert(changeset)
  end

  defp upload_file(file) do
    scope = %{"id" => UUID.generate()}
    case DocUpload.store({file, scope}) do
      {:ok, inserted} ->
        DocUpload.url({inserted, scope})
      _ ->
        nil
    end
  end

  defp get_class_from_hash(%{"class_hash" => class_hash, "period_id" => period_id}) do
    Classes.get_class_from_hash(class_hash, period_id)
  end

  defp add_grade_scale(%{"grade_scale" => %{"value" => ""}}, _class_id), do: nil
  defp add_grade_scale(%{"grade_scale" => %{"value" => val}}, class_id) do
    changes = %{"grade_scale" => val}
    Classes.get_class_by_id!(class_id)
    |> Universities.update_class(changes)
  end

  defp sammi(_class, %{"sammi" => ""}), do: nil
  defp sammi(%{id: id}, %{"sammi" => sammi}) do
    Logger.info(inspect(sammi))
    
    sammi = sammi
    |> String.replace("'", ~s("))

    case sammi |> Poison.decode do
      {:ok, decoded_sammi} ->
        decoded_sammi |> add_grade_scale(id)
        decoded_sammi |> add_professor_info(id)
      {:error, _} -> nil
    end
  end
  defp sammi(_class, _params), do: nil

  defp add_professor_info(%{"professor_info" => professor_info}, class_id) do
    class = Classes.get_class_by_id!(class_id)
            |> Repo.preload(:professor)
    case class.professor do
      nil -> nil
      professor -> 
        professor_info 
        |> extract_professor_details()
        |> Map.put("class_period_id", class.class_period_id)
        |> update_professor(professor)
    end
  end

  defp update_professor(params, professor) do
    params = params |> Map.delete("name_first")
    |> Map.delete("name_last")
    Professors.update_professor(professor, params)
  end

  defp extract_professor_details(professor_info) do
    Map.new()
    |> get_name(professor_info)
    |> get_office_hours(professor_info)
    |> get_office_location(professor_info)
    |> get_phone(professor_info)
    |> get_email(professor_info)
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

  defp get_email(map, %{"email" => %{"value" => ""}}), do: map |> Map.put("email", nil)
  defp get_email(map, %{"email" => %{"value" => val}}) do
    val = val |> String.trim()
    map |> Map.put("email", val)
  end
end