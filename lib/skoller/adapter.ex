defmodule Skoller.Adapter do
  defmacro __using__([model: model]) do
    quote do
      alias Skoller.Repo
      alias unquote(model), as: Model
      
      import Ecto.Query

      def get_by_id(id), do: Repo.get(Model, id)

      def index(query_params) when is_list(query_params),
        do:
          from(m in Model, where: ^query_params)
          |> Repo.all()

      def update(id, %{} = params) when is_integer(id), do: get_by_id(id) |> __MODULE__.update(params)

      def update(%Model{} = object, %{} = params),
        do: object |> Model.changeset(params) |> Repo.update()

      def create(%{} = params), do: params |> Model.insert_changeset() |> Repo.insert()

      defoverridable create: 1, update: 2, index: 1, get_by_id: 1
    end
  end
end
