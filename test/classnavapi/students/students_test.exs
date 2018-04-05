defmodule Classnavapi.StudentsTest do
  use ExUnit.Case, async: true
  use Classnavapi.DataCase
  doctest Classnavapi.Students, 
    except: [get_schools_with_enrollment: 0,
      get_field_of_study_count_by_school_id: 1,
      get_schools_for_student_subquery: 0
    ]
end
