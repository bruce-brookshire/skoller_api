defmodule SkollerWeb.SkollerJobs.JobProfileTypesView do
  use SkollerWeb, :view

  alias SkollerWeb.SkollerJobs.JobProfileTypesView

  def render("show.json", %{type: type}), do: Map.take(type, [:id, :name])

  def render("index.json", %{types: types}), do: render_many(types, JobProfileTypesView, "show.json", as: :type)
end
