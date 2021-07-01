defmodule Skoller.Factory do
  @moduledoc "Skoller Factory"
  use ExMachina.Ecto, repo: Skoller.Repo

  alias Skoller.Assignments.Assignment
  alias Skoller.Classes.Class
  alias Skoller.Users.User

  def assignment_factory, do: %Assignment{}
  def class_factory, do: %Class{}
  def user_factory, do: %User{}
end
