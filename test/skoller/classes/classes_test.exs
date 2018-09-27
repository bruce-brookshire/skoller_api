defmodule Skoller.ClassesTest do
  use ExUnit.Case, async: true
  use Skoller.DataCase
  doctest Skoller.Classes, except: [
    get_class_by_id: 1,
    get_class_by_id!: 1,
    create_class: 2,
    update_class: 2
  ]
end
