defmodule ClassnavapiWeb.Api.V1.UserControllerTest do
  use ClassnavapiWeb.ConnCase

  alias Classnavapi.Repo
  alias Classnavapi.User

  setup do
    {:ok, jwt, _} = Classnavapi.Auth.encode_and_sign(%{:id => 1}, %{typ: "access"})
    {:ok, %{jwt: jwt}}
  end

  @valid_school_attrs %{adr_city: "Nashville",
                      adr_line_1: "530 Church St", 
                      adr_line_2: "Suite 405", 
                      adr_state: "TN", 
                      adr_zip: "6158675309",
                      is_active: true,
                      is_editable: true,
                      name: "HKU",
                      timezone: "-8",
                      email_domains: [
                          %{
                              email_domain: "@example.com",
                              is_professor_only: true
                          },
                          %{
                              email_domain: "@edu.edu",
                              is_professor_only: false
                          }
                      ]}

  @valid_student_attrs %{birthday: "2017-10-12T18:51:53Z", 
                          gender: "male", 
                          name_first: "Sean", 
                          name_last: "Paul", 
                          phone: "2813348004", 
                          major: "CS", 
                          school_id: 1}

  test "index/2 responds with all Users", %{jwt: jwt} do
    john = User.changeset_insert(%User{}, %{email: "john@example.com", password: "test"})
    |> Repo.insert!
    
    jane = User.changeset_insert(%User{}, %{email: "jane@example.com", password: "test"})
    |> Repo.insert!

    response = build_conn()
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> get(v1_user_path(build_conn(), :index))
    |> json_response(200)

    expected = [
        %{ "email" => "john@example.com", "id" => john.id},
        %{ "email" => "jane@example.com", "id" => jane.id}
    ]

    assert  response == expected
  end

  test "show/2 responds with a users id if the user is found", %{jwt: jwt} do
    user = User.changeset_insert(%User{}, %{email: "test@example.com", password: "test"})
    |> Repo.insert!

    response = build_conn()
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> get(v1_user_path(build_conn(), :show, user.id))
    |> json_response(200)

    expected = %{ "email" => "test@example.com", "id" => user.id, "student" => nil}

    assert  response == expected
  end

  test "show/2 responds with an error when no user is found", %{jwt: jwt} do
    assert_raise Ecto.NoResultsError, fn ->
        build_conn()
        |> put_req_header("authorization", "Bearer #{jwt}")
        |> get(v1_user_path(build_conn(), :show, 1))
        |> json_response(404)
    end
  end

  test "Create/2 creates and responds with a newly created user if attributes are valid", %{jwt: jwt} do

    response = build_conn()
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(v1_user_path(build_conn(), :create, email: "test@example.com", password: "test"))
    |> json_response(200)

    assert response["id"] |> is_integer
    assert response["id"] > 0
    assert response["email"] == "test@example.com"
    assert response["student"] == nil
  end

  test "Create/2 creates and responds with a new user with student if attributes are valid", %{jwt: jwt} do

    school = Classnavapi.School.changeset_insert(%Classnavapi.School{}, @valid_school_attrs)
    |> Repo.insert!
    
    student = %{@valid_student_attrs | school_id: school.id}

    response = build_conn()
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(v1_user_path(build_conn(), :create, email: "test@example.com", password: "test", student: student))
    |> json_response(200)

    assert response["id"] |> is_integer
    assert response["id"] > 0
    assert response["email"] == "test@example.com"
    assert response["student"]["id"] |> is_integer
    assert response["student"]["id"] > 0
  end

  test "Create/2 responds in error if school does not exist", %{jwt: jwt} do

    student = @valid_student_attrs

    response = build_conn()
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(v1_user_path(build_conn(), :create, email: "test@example.com", password: "test", student: student))
    |> json_response(422)

    expected = %{"errors" => %{"student" => ["Invalid school"]}}

    assert response == expected
  end

  test "Create/2 does not create user and returns in error if email is invalid", %{jwt: jwt} do
    
    response = build_conn()
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(v1_user_path(build_conn(), :create, email: "test.com", password: "test"))
    |> json_response(422)

    expected = %{"errors" => %{"email" => ["has invalid format"]}}

    assert response == expected
  end

  test "Create/2 does not create user and returns in error if required fields are missing", %{jwt: jwt} do
    
    response = build_conn()
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> post(v1_user_path(build_conn(), :create, email: "", password: ""))
    |> json_response(422)

    expected = %{"errors" => %{"email" => ["can't be blank"], "password" => ["can't be blank"]}}

    assert response == expected
  end

  test "Update/2 does not update email and updates other fields when valid", %{jwt: jwt} do
    user = User.changeset_insert(%User{}, %{email: "test@example.com", password: "test"})
    |> Repo.insert!

    response = build_conn()
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> put(v1_user_path(build_conn(), :update, user.id, email: "update@example.com", password: "update"))
    |> json_response(200)

    user_updated = Repo.get(User, response["id"])

    assert response["id"] |> is_integer
    assert response["id"] == user.id
    assert response["email"] == "test@example.com"
    assert response["student"] == nil
    assert user_updated.password == "update"
  end

  test "Update/2 does not update when required fields missing", %{jwt: jwt} do
    user = User.changeset_insert(%User{}, %{email: "test@example.com", password: "test"})
    |> Repo.insert!

    response = build_conn()
    |> put_req_header("authorization", "Bearer #{jwt}")
    |> put(v1_user_path(build_conn(), :update, user.id, email: "update@example.com", password: ""))
    |> json_response(422)
    
    expected = %{"errors" => %{"password" => ["can't be blank"]}}

    assert response == expected
  end
end