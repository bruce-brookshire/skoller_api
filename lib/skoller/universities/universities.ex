defmodule Skoller.Universities do
  @moduledoc """
  Context module for universities
  """

  alias Skoller.Repo
  alias Skoller.Schools.Class

  @doc false
  def get_changeset(old_class \\ %Class{}, params) do
    Class.university_changeset(old_class, params)
  end

  @doc """
  Updates a class.

  ## Returns
  `{:ok, Skoller.Schools.Class}` or `{:error, Ecto.Changeset}`
  """
  def update_class(%Class{} = class, params) do
    Class.university_changeset(class, params)
    |> Repo.update()
  end

  @doc """
  Gets a class by crn

  ## Returns
  `Skoller.Schools.Class` or `nil`
  """
  def get_class_by_crn(crn, class_period_id) do
    Repo.get_by(Class, class_period_id: class_period_id, crn: crn)
  end
end