defmodule Skoller.Organizations.OrgGroupStudents do
  alias Skoller.Organizations.OrgGroupStudents.OrgGroupStudent
  alias Skoller.Repo

  def get_by_id(id), do: Repo.get(OrgGroupStudent, id)

  def update(id, params) when is_integer(id), do: get_by_id(id) |> update(params)

  def update(%OrgGroupStudent{} = student, params),
    do: student |> OrgGroupStudent.changeset(params) |> Repo.update()

  def create(params), do: params |> OrgGroupStudent.insert_changeset() |> Repo.insert()
end
