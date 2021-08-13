defmodule SkollerWeb.Responses.MultiError do
  @moduledoc """
  Helper for `Ecto.Multi` errors.
  """

  use SkollerWeb, :controller
  alias SkollerWeb.ChangesetView
  alias SkollerWeb.ErrorView

  def render(conn, %Ecto.Changeset{} = changeset) do
    conn
    |> put_status(:unprocessable_entity)
    |> render(ChangesetView, "error.json", changeset: changeset)
  end

  def render(conn, %{} = failed_value) do
    conn
    |> put_status(:unprocessable_entity)
    |> render(ErrorView, "error.json", error: failed_value)
  end
end