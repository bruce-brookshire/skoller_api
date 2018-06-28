defmodule Skoller.StudentsTest do
  use ExUnit.Case, async: true
  use Skoller.DataCase
  doctest Skoller.Students, 
    except: [get_field_of_study_count_by_school_id: 1,
      get_enrolled_student_classes_subquery: 0,
      get_enrolled_student_classes_subquery: 1,
      get_enrolled_classes_by_student_id: 1
    ]
end
