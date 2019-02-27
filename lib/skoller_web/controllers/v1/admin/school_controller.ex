defmodule SkollerWeb.Api.V1.Admin.SchoolController do
  @moduledoc false
  
  use SkollerWeb, :controller

  alias SkollerWeb.Admin.SchoolView
  alias Skoller.Schools
  alias Skoller.Students
  alias Skoller.EnrolledSchools
  alias Skoller.Repo

  import SkollerWeb.Plugs.Auth
  
  @admin_role 200
  
  plug :verify_role, %{role: @admin_role}

  def index(conn, params) do
    schools = Schools.get_schools(params)
    render(conn, SchoolView, "index.json", schools: schools)
  end

  def show(conn, %{"id" => id}) do
    school = Schools.get_school_by_id!(id)
    render(conn, SchoolView, "show.json", school: school)
  end

  def hub(conn, params) do
    schools = EnrolledSchools.get_schools_with_enrollment(params)
    render(conn, SchoolView, "index.json", schools: schools)
  end

  def update(conn, %{"id" => id} = params) do
    school_old = Schools.get_school_by_id!(id)

    case Schools.update_school(school_old, params) do
      {:ok, school} ->
        render(conn, SchoolView, "show.json", school: school)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def csv(conn, _params) do
    schools = Schools.get_schools() |> Repo.preload(:email_domains)
    filename = get_filename()
    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", ~s[attachment; filename="#{filename}"; filename*="#{filename}"])
    |> send_resp(200, csv_schools(schools))
  end
  defp get_filename() do
    now = DateTime.utc_now
    "Schools-#{now.month}_#{now.day}_#{now.year}_#{now.hour}_#{now.minute}_#{now.second}.csv"
  end
  defp csv_schools(schools) do
    schools
    |> Enum.map(&get_row_data(&1))
    |> CSV.encode
    |> Enum.to_list
    |> add_headers
    |> to_string
  end
  defp get_row_data(school) do
    students = Students.get_main_school_students(school)

    [
      "#{school.inserted_at.month}/#{school.inserted_at.day}/#{school.inserted_at.year} #{school.inserted_at.hour}:#{school.inserted_at.minute}:#{school.inserted_at.second}",
      school.name,
      school.adr_locality,
      school.adr_region,
      school.timezone,
      stringify_domains(school.email_domains),
      school.color,
      Enum.count(students)
    ]
  end
  defp add_headers(list) do

    [
      "School Creation Date," <>
      "School Name," <>
      "City," <>
      "State," <>
      "Timezone," <>
      "Email Domains," <>
      "Color," <>
      "# of Accounts\r\n"
      | list
    ]
  end
  defp stringify_domains(nil), do: ""
  defp stringify_domains(domains) do
    Enum.reduce(domains, "", fn domain, acc ->
      acc <> domain.email_domain <> "|"
    end)
  end

end