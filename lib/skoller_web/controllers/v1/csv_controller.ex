defmodule SkollerWeb.Api.V1.CSVController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias Skoller.FieldsOfStudy
  alias SkollerWeb.CSVView
  alias Skoller.Classes
  alias Skoller.Universities
  alias Skoller.Professors
  alias Skoller.Schools
  alias Skoller.CSVUploads
  
  import SkollerWeb.Plugs.Auth
  
  @admin_role 200
  @headers [:campus, :class_type, :subject, :code, :section, :crn, :meet_days, :prof_name_first, :prof_name_last, :location, :name, :meet_start_time, :class_upload_key]
  @school_headers [:name, :adr_locality, :adr_region]

  plug :verify_role, %{role: @admin_role}

  def fos(conn, %{"file" => file}) do
    case CSVUploads.create_csv_upload(file.filename) do
      {:ok, _} ->
        uploads = file.path 
        |> File.stream!()
        |> CSV.decode(headers: [:field])
        |> Enum.map(&process_fos_row(&1))

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
    case CSVUploads.create_csv_upload(file.filename) do
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

  def school(conn, %{"file" => file}) do
    uploads = file.path 
    |> File.stream!()
    |> CSV.decode(headers: @school_headers)
    |> Enum.map(&process_school_row(&1))

    conn |> render(CSVView, "index.json", csv: uploads)
  end

  defp process_school_row(school) do
    case school do
      {:ok, school} ->
        school
        |> Map.put(:adr_country, "us")
        |> Schools.create_school()
      {:error, error} ->
        {:error, error}
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
    school = Schools.get_school_from_period(class_period_id)
    case Professors.get_professor_by_name(name_first, name_last, school.id) do
      nil -> 
        Professors.create_professor(%{name_first: name_first, name_last: name_last, school_id: school.id})
      prof ->
        {:ok, prof}
    end
  end

  defp process_fos_row(fos) do
    case fos do
      {:ok, field} ->
        field 
        |> FieldsOfStudy.create_field_of_study()
      {:error, error} ->
        {:error, error}
    end
  end
end