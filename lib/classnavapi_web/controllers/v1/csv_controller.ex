defmodule ClassnavapiWeb.Api.V1.CSVController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Repo
  alias Classnavapi.School.FieldOfStudy
  alias ClassnavapiWeb.CSVView
  alias Classnavapi.Professor
  alias Classnavapi.Class
  alias Classnavapi.CSVUpload  
  
  import ClassnavapiWeb.Helpers.AuthPlug
  
  @admin_role 200
  @default_grade_scale "A,90|B,80|C,70|D,60"
  
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
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def class(conn, %{"file" => file, "period_id" => period_id}) do
    changeset = CSVUpload.changeset(%CSVUpload{}, %{name: file.filename})
    case Repo.insert(changeset) do
      {:ok, _} ->
        period_id = period_id |> String.to_integer
        uploads = file.path 
        |> File.stream!()
        |> CSV.decode(headers: [:campus, :number, :crn, :meet_days,
                                :class_end, :meet_end_time, :prof_name_first, :prof_name_last,
                                :location, :name, :class_type, :class_start, :meet_start_time, :upload_key])
        |> Enum.map(&process_class_row(&1, period_id))

        conn |> render(CSVView, "index.json", csv: uploads)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  defp process_class_row(class, period_id) do
    case class do
      {:ok, class} ->
        class = class |> Map.put(:class_period_id, period_id)
                      |> Map.put(:grade_scale, @default_grade_scale)
        class = case process_professor(class) do
          {:ok, prof} -> class |> Map.put(:professor_id, prof.id)
          {:error, _} -> class
        end
        changeset = Class.changeset_insert(%Class{}, class)
        changeset = changeset |> Ecto.Changeset.change(%{class_upload_key: class.upload_key})
        Repo.insert(changeset)
      {:error, error} ->
        {:error, error}
    end
  end

  defp process_professor(%{prof_name_first: name_first, prof_name_last: name_last, class_period_id: class_period_id}) do
    case Repo.get_by(Professor, name_first: name_first, name_last: name_last, class_period_id: class_period_id) do
      nil -> insert_professor(%{name_first: name_first, name_last: name_last, class_period_id: class_period_id})
      prof -> {:ok, prof}
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