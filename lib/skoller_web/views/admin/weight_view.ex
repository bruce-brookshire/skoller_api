defmodule SkollerWeb.Admin.WeightView do
  @moduledoc false
  use SkollerWeb, :view

  alias SkollerWeb.Admin.WeightView, as: AdminWeightView
  alias SkollerWeb.Class.WeightView, as: WeightView
  
  def render("show.json", %{weight: weight}) do
    render_one(weight, AdminWeightView, "weight.json")
  end

  def render("weight.json", %{weight: weight}) do
    weight = weight |> Skoller.Repo.preload([:created_by_user, :updated_by_user])
    render_one(weight, WeightView, "show.json")
    |> Map.merge(%{
      created_by: (if (weight.created_by_user != nil), do: weight.created_by_user.email, else: nil),
      updated_by: (if (weight.updated_by_user != nil), do: weight.updated_by_user.email, else: nil)
    })
  end
end