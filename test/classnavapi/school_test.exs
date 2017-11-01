defmodule Classnavapi.SchoolTest do
  use Classnavapi.DataCase

  alias Classnavapi.School

  @valid_attrs %{adr_city: "Nashville",
                adr_line_1: "530 Church St", 
                adr_line_2: "Suite 405", 
                adr_state: "TN", 
                adr_zip: "6158675309",
                is_active_enrollment: true,
                is_readonly: true,
                name: "HKU",
                timezone: "-8",
                email_domains: [
                    %{
                        email_domain: "@test",
                        is_professor_only: true
                    },
                    %{
                        email_domain: "@edu",
                        is_professor_only: false
                    }
                ]}

  test "school insert with valid attributes" do
    changeset = School.changeset_insert(%School{}, @valid_attrs)
    assert changeset.valid?
  end

  test "school insert without optional adr line 2" do
    changeset = School.changeset_insert(%School{}, Map.delete(@valid_attrs, :adr_line_2))
    assert changeset.valid?
  end

  test "school insert without active flag" do
    changeset = School.changeset_insert(%School{}, Map.delete(@valid_attrs, :is_active_enrollment))
    assert changeset.valid?
  end

  test "school insert without editable flag" do
    changeset = School.changeset_insert(%School{}, Map.delete(@valid_attrs, :is_readonly))
    assert changeset.valid?
  end

  test "school insert with no city" do
    changeset = School.changeset_insert(%School{}, Map.delete(@valid_attrs, :adr_city))
    refute changeset.valid?
  end

  test "school insert with no adr line 1" do
    changeset = School.changeset_insert(%School{}, Map.delete(@valid_attrs, :adr_line_1))
    refute changeset.valid?
  end

  test "school insert with no state" do
    changeset = School.changeset_insert(%School{}, Map.delete(@valid_attrs, :adr_state))
    refute changeset.valid?
  end

  test "school insert with no zip code" do
    changeset = School.changeset_insert(%School{}, Map.delete(@valid_attrs, :adr_zip))
    refute changeset.valid?
  end

  test "school insert with no name" do
    changeset = School.changeset_insert(%School{}, Map.delete(@valid_attrs, :name))
    refute changeset.valid?
  end

  test "school insert with no timezone" do
    changeset = School.changeset_insert(%School{}, Map.delete(@valid_attrs, :timezone))
    refute changeset.valid?
  end

  test "school insert with no email domain" do
    changeset = School.changeset_insert(%School{}, Map.delete(@valid_attrs, :email_domains))
    refute changeset.valid?
  end
end