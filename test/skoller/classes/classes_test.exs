defmodule Skoller.ClassesTest do
  use ExUnit.Case, async: true
  use Skoller.DataCase
  doctest Skoller.Classes, except: [get_status_counts: 1]
end
