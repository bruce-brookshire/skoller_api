defmodule ClassnavapiWeb.Api.V1.CSVController do
  use ClassnavapiWeb, :controller

  alias Classnavapi.Repo
  alias Classnavapi.School.FieldOfStudy
  alias ClassnavapiWeb.CSVView
  
  import ClassnavapiWeb.Helpers.AuthPlug
  
  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

  def fos(conn, %{"file" => file, "school_id" => school_id} = params) do
    school_id = school_id |> String.to_integer
    uploads = file.path 
    |> File.stream!()
    |> CSV.decode()
    |> Enum.map(&process_fos_row(&1, school_id))

    conn |> render(CSVView, "index.json", csv: uploads)
  end

  defp process_fos_row(fos, school_id) do
    case fos do
      {:ok, field} ->
        field = field |> List.first()
        changeset = FieldOfStudy.changeset(%FieldOfStudy{}, %{field: field, school_id: school_id})
        Repo.insert(changeset)
      {:error, error} ->
        {:error, error}
    end
  end
end