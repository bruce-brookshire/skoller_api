defmodule Skoller.ClassesTest do
  use ExUnit.Case, async: true
  use Skoller.DataCase
  doctest Skoller.Classes, except: [
    get_status_counts: 1,
    get_class_by_id: 1
  ]
end
