defmodule Classnavapi.StudentsTest do
  use ExUnit.Case, async: true
  use Classnavapi.DataCase
  doctest Classnavapi.Students, except: [get_schools_with_enrollment: 0]
end
