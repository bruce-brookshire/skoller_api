defmodule SkollerWeb.Api.V1.Stripe.CancellationReasonController do
  use SkollerWeb, :controller
  alias Skoller.CancellationReasons

  def create(conn, params) do
    params = Map.merge(params, %{"user_id" => conn.assigns.user.id})

    case CancellationReasons.create(params) do
      {:ok, _cancellation_reason} ->
        conn
        |> json(%{status: :ok, message: "Your feedback was given"})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(SkollerWeb.ChangesetView)
        |> render("error.json", changeset: changeset)
    end
  end
end