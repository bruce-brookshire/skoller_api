defmodule SkollerWeb.View do
  defmacro __using__(params) do
    %{
      single_atom: single_atom,
      plural_atom: plural_atom,
      model: model
    } = params |> Map.new()

    quote do
      use SkollerWeb, :view

      alias unquote(model), as: Model

      def single_atom, do: unquote(single_atom)
      def plural_atom, do: unquote(plural_atom)

      def render("show.json", %{unquote(single_atom) => object}) do
        fields = Model.__schema__(:fields)

        Map.take(object, fields)
      end

      def render("index.json", %{unquote(plural_atom) => objects}) do
        render_many(objects, __MODULE__, "show.json", as: single_atom())
      end

      defoverridable render: 2
    end
  end
end
