defmodule SkollerWeb.Controller do
  defmacro __using__(params) do
    %{adapter: adapter, view: view} = Map.new(params)

    quote do
      use SkollerWeb, :controller

      alias unquote(adapter), as: Adapter
      alias unquote(view), as: View

      def show(conn, %{"id" => id}) do
        case Adapter.get_by_id(id) do
          %{} = object ->
            conn
            |> put_view(View)
            |> render("show.json", [{View.single_atom(), object}])

          _ ->
            send_resp(conn, 422, "Unprocessable Entity")
        end
      end

      # def index()

      def update(conn, %{"id" => id} = params) do
        case Adapter.update(id, params) do
          {:ok, %{} = object} ->
            conn
            |> put_view(View)
            |> render("show.json", [{View.single_atom(), object}])

          _ ->
            send_resp(conn, 422, "Unprocessable Entity")
        end
      end

      def create(conn, params) do
        case Adapter.create(params) |> IO.inspect do
          {:ok, %{} = object} ->
            conn
            |> put_view(View)
            |> render("show.json", [{View.single_atom(), object}])

          _ ->
            send_resp(conn, 422, "Unprocessable Entity")
        end
      end

      defoverridable [show: 2, update: 2, create: 2]
    end
  end
end
