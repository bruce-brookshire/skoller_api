defmodule Skoller.Periods.Devices do
  @moduledoc """
  A context module for users in a period
  """

  alias Skoller.Repo
  alias Skoller.Classes.Class
  alias Skoller.Devices.Device
  alias Skoller.Users.User
  alias Skoller.Students.Student
  alias Skoller.EnrolledStudents

  import Ecto.Query

  @doc """
  Gets a list of all devices in a period
  """
  def get_devices_by_period(period_id) do
    from(d in Device)
    |> join(:inner, [d], u in User, on: u.id == d.user_id)
    |> join(:inner, [d, u], s in Student, on: s.id == u.student_id)
    |> join(:inner, [d, u, s], sc in subquery(EnrolledStudents.enrolled_student_class_subquery()), on: sc.student_id == s.id)
    |> join(:inner, [d, u, s, sc], c in Class, on: c.id == sc.class_id)
    |> where([d, u, s, sc, c], c.class_period_id == ^period_id)
    |> Repo.all()
  end
end