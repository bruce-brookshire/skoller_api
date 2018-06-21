defmodule Skoller.HighSchools do
  @moduledoc """
  Context module for high schools
  """
  
  alias Skoller.Repo
  alias Skoller.Schools.Class

  @doc false
  def get_changeset(old_class \\ %Class{}, params) do
    Class.hs_changeset(old_class, params)
  end

  @doc """
  Updates a high school

  ## Returns
  `{:ok, Skoller.Schools.Class}` or `{:error, Ecto.Changeset}`
  """
  def update_class(%Class{} = class, params) do
    Class.hs_changeset(class, params)
    |> Repo.update()
  end
end