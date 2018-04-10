defmodule SkollerWeb.Api.V1.CSVController do
  use SkollerWeb, :controller

  alias Skoller.Repo
  alias Skoller.School.FieldOfStudy
  alias SkollerWeb.CSVView
  alias Skoller.Professor
  alias Skoller.CSVUpload  
  alias Skoller.Classes
  alias Skoller.Universities
  
  import SkollerWeb.Helpers.AuthPlug
  import Ecto.Query
  
  @admin_role 200
  @headers [:campus, :class_type, :number, :crn, :meet_days, :meet_end_time, :prof_name_first, :prof_name_last, :location, :name, :meet_start_time, :upload_key]
  
  plug :verify_role, %{role: @admin_role}

  def fos(conn, %{"file" => file, "school_id" => school_id}) do
    changeset = CSVUpload.changeset(%CSVUpload{}, %{name: file.filename})
    case Repo.insert(changeset) do
      {:ok, _} ->
        school_id = school_id |> String.to_integer
        uploads = file.path 
        |> File.stream!()
        |> CSV.decode(headers: [:field])
        |> Enum.map(&process_fos_row(&1, school_id))

        conn |> render(CSVView, "index.json", csv: uploads)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def class(conn, %{"file" => file, "period_id" => period_id, "check_filenames" => "false"}) do
    period_id = period_id |> String.to_integer
    uploads = file.path 
    |> File.stream!()
    |> CSV.decode(headers: @headers)
    |> Enum.map(&process_class_row(&1, period_id))

    conn |> render(CSVView, "index.json", csv: uploads)
  end

  def class(conn, %{"file" => file, "period_id" => period_id}) do
    changeset = CSVUpload.changeset(%CSVUpload{}, %{name: file.filename})
    case Repo.insert(changeset) do
      {:ok, _} ->
        period_id = period_id |> String.to_integer
        uploads = file.path 
        |> File.stream!()
        |> CSV.decode(headers: @headers)
        |> Enum.map(&process_class_row(&1, period_id))

        conn |> render(CSVView, "index.json", csv: uploads)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  defp process_class_row(class, period_id) do
    case class do
      {:ok, class} ->
        class = class 
        |> Map.put(:class_period_id, period_id)
        class = case process_professor(class) do
          {:ok, prof} -> class |> Map.put(:professor_id, prof.id)
          {:error, _} -> class |> Map.put(:professor_id, nil)
        end
        # TODO: Determine way to find HS classes.
        case Universities.get_class_by_crn(class.crn, class.class_period_id) do
          nil -> class |> Classes.create_class()
          existing -> existing |> Classes.update_class(class)
        end
      {:error, error} ->
        {:error, error}
    end
  end

  defp process_professor(%{prof_name_first: name_first, prof_name_last: name_last, class_period_id: class_period_id}) do
    name_first = name_first |> String.trim()
    name_last = name_last |> String.trim()
    prof = from(p in Professor)
    |> where([p], p.name_first == ^name_first and p.name_last == ^name_last and p.class_period_id == ^class_period_id)
    |> Repo.all
    case prof do
      [] -> 
        insert_professor(%{name_first: name_first, name_last: name_last, class_period_id: class_period_id})
      prof -> 
        prof = prof |> List.first()
        {:ok, prof}
    end
  end

  defp insert_professor(params) do
    changeset = Professor.changeset_insert(%Professor{}, params)
    Repo.insert(changeset)
  end

  defp process_fos_row(fos, school_id) do
    case fos do
      {:ok, field} ->
        field = field |> Map.put(:school_id, school_id)
        changeset = FieldOfStudy.changeset(%FieldOfStudy{}, field)
        Repo.insert(changeset)
      {:error, error} ->
        {:error, error}
    end
  end
end