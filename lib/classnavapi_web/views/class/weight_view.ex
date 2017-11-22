defmodule ClassnavapiWeb.Class.WeightView do
    use ClassnavapiWeb, :view

    alias ClassnavapiWeb.Class.WeightView

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
            weight: Decimal.to_float(weight.weight)
        }
    end
end
