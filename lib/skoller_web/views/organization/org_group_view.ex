defmodule SkollerWeb.Organization.OrgGroupView do
  use SkollerWeb, :view

  import ExMvc.View

  alias Skoller.Organizations.OrgGroups.OrgGroup

  def render("show.json", %{model: model}) do
    fields = Map.take(model, OrgGroup.__schema__(:fields) ++ [:metrics])

    associations =
      :associations
      |> OrgGroup.__schema__()
      |> Enum.map(&{&1, Map.get(model, &1) |> render_association()})
      |> Map.new

    Map.merge(fields, associations)
  end

  def render("index.json", %{models: models}),
    do: render_many(models, __MODULE__, "show.json", as: :model)
end
