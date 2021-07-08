defmodule Skoller.Factory do
  @moduledoc "Skoller Factory"
  use ExMachina.Ecto, repo: Skoller.Repo
  use Skoller.Schema

  def assignment_factory do
    %Assignment{
      name: sequence("assignment"),

    }
  end
  
  def class_factory, do: %Class{}
  
  def role_factory do
    %Role{
      id: 200,
      name: "admin",
      inserted_at: Timex.now()
    }
  end
  
  def student_factory, do: %Student{}
  
  def user_factory, do: %User{}

  def user_role_factory, do: %UserRole{}

  def weight_factory, do: %Weight{}
end
