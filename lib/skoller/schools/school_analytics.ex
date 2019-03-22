defmodule Skoller.Schools.SchoolAnalytics do


  alias Skoller.Repo
  alias Skoller.Schools
  alias Skoller.Students

  def get_analytics() do
    Schools.get_schools() 
      |> Repo.preload(:email_domains)
      |> Enum.map(&get_row_data(&1))
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
  
  defp stringify_domains(nil), do: ""
  defp stringify_domains(domains) do
    Enum.reduce(domains, "", fn domain, acc ->
      acc <> domain.email_domain <> "|"
    end)
  end

end