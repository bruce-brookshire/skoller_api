defmodule ClassnavapiWeb.Api.V1.Admin.Class.ScriptDocController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Class
  alias Classnavapi.ClassPeriod
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

  require Logger
  
  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

  def create(%{assigns: %{user: user}} = conn, %{"file" => file} = params) do

    class = params |> get_class_from_hash()

    class |> sammi(params)

    location = file |> upload_file()

    params = params 
    |> Map.put("path", location)
    |> Map.put("name", file.filename)
    |> Map.put("class_id", class.id)
    |> Map.put("is_syllabus", true)
    |> Map.put("user_id", user.id)

    changeset = Doc.changeset(%Doc{}, params)

    multi = Ecto.Multi.new
    |> Ecto.Multi.insert(:doc, changeset)
    |> Ecto.Multi.run(:status, &StatusHelper.check_status(class, &1))

    case Repo.transaction(multi) do
      {:ok, %{doc: doc}} ->
        render(conn, DocView, "show.json", doc: doc)
      {:error, _, failed_value, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ChangesetView, "error.json", changeset: failed_value)
    end
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
    from(class in Class)
    |> join(:inner, [class], period in ClassPeriod, class.class_period_id == period.id)
    |> where([class, period], period.id == ^period_id)
    |> where([class], class.class_upload_key == ^class_hash)
    |> Repo.one!()
  end

  defp add_grade_scale(%{"grade_scale" => %{"value" => ""}}, _class_id), do: nil
  defp add_grade_scale(%{"grade_scale" => %{"value" => val}}, class_id) do
    class = Repo.get!(Class, class_id)
    Class.changeset(class, %{"grade_scale" => val})
    |> Repo.update()
  end

  defp sammi(_class, %{"sammi" => ""}), do: nil
  defp sammi(%Class{id: id}, %{"sammi" => sammi}) do
    Logger.info(inspect(sammi))
    
    decoded_sammi = sammi
    |> String.replace("'", ~s("))
    |> Poison.decode!

    decoded_sammi |> add_grade_scale(id)
    decoded_sammi |> add_professor_info(id)
  end
  defp sammi(_class, _params), do: nil

  defp add_professor_info(%{"professor_info" => professor_info}, class_id) do
    class = Repo.get!(Class, class_id)
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
    Professor.changeset_update(professor, params)
    |> Repo.update()
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