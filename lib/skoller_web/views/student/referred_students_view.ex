defmodule SkollerWeb.Student.ReferredStudentsView do
  @moduledoc false

  use SkollerWeb, :view

  def render("referred_students.json", %{referred_students: referred_students, student: student}) do
    %{student_data: %{referred_students: referred_students, student: student}}
  end
end
