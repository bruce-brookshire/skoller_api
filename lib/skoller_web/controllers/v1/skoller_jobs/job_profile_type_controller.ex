defmodule SkollerWeb.Api.V1.SkollerJobs.JobProfileTypeController do
  use SkollerWeb, :controller

  alias Skoller.Repo
  alias Skoller.SkollerJobs.DegreeType
  alias Skoller.SkollerJobs.EthnicityType
  alias Skoller.SkollerJobs.CareerActivityType
  alias Skoller.SkollerJobs.JobProfileStatus
  alias SkollerWeb.SkollerJobs.JobProfileTypesView

  def show(conn, %{"type" => "degrees"}), do: get_and_render(DegreeType, conn)
  def show(conn, %{"type" => "statuses"}), do: get_and_render(JobProfileStatus, conn)
  def show(conn, %{"type" => "activities"}), do: get_and_render(CareerActivityType, conn)
  def show(conn, %{"type" => "ethnicities"}), do: get_and_render(EthnicityType, conn)
  def show(conn, %{"type" => type}), do: send_resp(conn, 422, "#{type} not a resource")

  defp get_and_render(type_atom, conn),
    do:
      put_view(conn, JobProfileTypesView)
      |> render("index.json", types: Repo.all(type_atom))
end
