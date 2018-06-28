defmodule SkollerWeb.Helpers.RepoHelper do
  use SkollerWeb, :controller

  @moduledoc """
  
  Helper for Ecto.Multi errors.

  """

  def multi_error(conn, %Ecto.Changeset{} = changeset) do
    conn
    |> put_status(:unprocessable_entity)
    |> render(SkollerWeb.ChangesetView, "error.json", changeset: changeset)
  end

  def multi_error(conn, %{} = failed_value) do
    conn
    |> put_status(:unprocessable_entity)
    |> render(SkollerWeb.ErrorView, "error.json", error: failed_value)
  end

  def errors(tuple) do
    case tuple do
      {:error, _val} -> true
      _ -> false
    end
  end
end