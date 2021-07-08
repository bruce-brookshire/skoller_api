defmodule Skoller.Schema do
  @moduledoc "Skoller Schema"
  defmacro __using__(_) do
    quote do
      alias Skoller.{
        Assignments.Assignment,
        Classes.Class,
        Roles.Role,
        Students.Student,
        StudentAssignments.StudentAssignment,
        Users.User,
        UserRoles.UserRole,
        Weights.Weight
      }

      alias Skoller.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query, warn: false
      
      use Ecto.Schema
    end
  end
end
