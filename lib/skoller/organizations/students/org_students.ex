defmodule Skoller.Organization.OrgStudents do
  alias Skoller.Organization.OrgStudents.OrgStudent
  alias Skoller.Repo

  use Ecto.Schema


  def get_by_id(id), do: Repo.get(OrgStudent, id)

  # def update(id, params) when is_integer(id), do: get_by_id()
end 