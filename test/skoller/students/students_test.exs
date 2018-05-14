defmodule Skoller.StudentsTest do
  use ExUnit.Case, async: true
  use Skoller.DataCase
  doctest Skoller.Students, 
    except: [get_schools_with_enrollment: 0,
      get_schools_for_student_subquery: 0,
      get_enrolled_student_classes_subquery: 0,
      get_enrolled_student_classes_subquery: 1,
      get_enrolled_classes_by_student_id: 1
    ]
end
