defmodule Classnavapi.Students do
  
    alias Classnavapi.Repo
    alias Classnavapi.Class.StudentClass
    alias Classnavapi.Class
  
    import Ecto.Query
  
    def get_student_count_by_period(period_id) do
      from(sc in StudentClass)
      |> join(:inner, [sc], c in Class, c.id == sc.class_id)
      |> where([sc, c], c.class_period_id == ^period_id)
      |> where([sc], sc.is_dropped == false)
      |> distinct([sc], sc.student_id)
      |> Repo.aggregate(:count, :id)
    end
  end