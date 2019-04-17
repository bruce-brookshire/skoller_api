defmodule Skoller.Mods.Users do
  @moduledoc """
  A context module that ties together mods and users.
  """

  alias Skoller.Users.User
  alias Skoller.Students.Student
  alias Skoller.Mods.Action
  alias Skoller.StudentClasses.StudentClass
  alias Skoller.Repo

  import Ecto.Query

  @doc """
  Gets avatar urls for students who accepted a given mod.

  ## Returns
  `[String]` or `[]`
  """
  def get_student_pic_by_mod_acceptance(mod_id) do
    from(user in User)
    |> join(:inner, [user], stu in Student, on: user.student_id == stu.id)
    |> join(:inner, [user, stu], sc in StudentClass, on: sc.student_id == stu.id)
    |> join(:inner, [user, stu, sc], act in Action, on: act.student_class_id == sc.id)
    |> where([user, stu, sc, act], act.assignment_modification_id == ^mod_id)
    |> where([user, stu, sc, act], act.is_accepted == true)
    |> select([user, stu, sc, act], user.pic_path)
    |> Repo.all()
  end
end