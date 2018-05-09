defmodule SkollerWeb.Class.WeightView do
    use SkollerWeb, :view

    alias SkollerWeb.Class.WeightView

    def render("index.json", %{weights: weights}) do
        render_many(weights, WeightView, "weight.json")
    end

    def render("show.json", %{weight: weight}) do
        render_one(weight, WeightView, "weight.json")
    end

    def render("weight.json", %{weight: weight}) do
        %{
            id: weight.id,
            name: weight.name,
            weight: Decimal.to_float(Decimal.round(weight.weight, 2)),
            inserted_at: weight.inserted_at
        }
    end
end
