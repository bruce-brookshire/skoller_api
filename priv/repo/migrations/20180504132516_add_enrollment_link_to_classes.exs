defmodule Skoller.Repo.Migrations.AddEnrollmentLinkToClasses do
  use Ecto.Migration
  alias Skoller.Students
  alias Skoller.Class.StudentClass
  alias Skoller.Repo

  import Ecto.Query

  def up do
    from(sc in StudentClass)
    |> where([sc], is_nil(sc.enrollment_link))
    |> Repo.all()
    |> Enum.map(&Students.generate_enrollment_link(&1))
  end
end
