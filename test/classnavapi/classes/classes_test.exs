defmodule Classnavapi.ClassesTest do
  use ExUnit.Case, async: true
  use Classnavapi.DataCase
  doctest Classnavapi.Classes, except: [get_status_counts: 1]
end
