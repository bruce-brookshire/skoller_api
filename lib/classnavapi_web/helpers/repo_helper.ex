defmodule ClassnavapiWeb.Helpers.RepoHelper do
  use ClassnavapiWeb, :controller

  @moduledoc """
  
  Helper for Ecto.Multi errors.

  """

  def multi_error(conn, %Ecto.Changeset{} = changeset) do
    conn
    |> put_status(:unprocessable_entity)
    |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
  end

  def multi_error(conn, %{} = failed_value) do
    conn
    |> put_status(:unprocessable_entity)
    |> render(ClassnavapiWeb.ErrorView, "error.json", error: failed_value)
  end
end