defmodule ClassnavapiWeb.Api.V1.SchoolControllerTest do
    use ClassnavapiWeb.ConnCase
  
    alias Classnavapi.Repo
    alias Classnavapi.School
  
    setup do
      {:ok, jwt, _} = Classnavapi.Auth.encode_and_sign(%{:id => 1}, %{typ: "access"})
      {:ok, %{jwt: jwt}}
    end
  
    @valid_school_hku %{adr_city: "Nashville",
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
                                email_domain: "@hku.edu",
                                is_professor_only: false
                            }
                        ]}

    @valid_school_bmu %{adr_city: "Nashville",
                        adr_line_1: "530 Church St", 
                        adr_line_2: "Suite 405", 
                        adr_state: "TN", 
                        adr_zip: "6158675309",
                        is_active_enrollment: true,
                        is_readonly: true,
                        name: "BMU",
                        timezone: "-8",
                        email_domains: [
                            %{
                                email_domain: "@bmu.edu",
                                is_professor_only: false
                            },
                            %{
                                email_domain: "@bmu1.edu",
                                is_professor_only: false
                            }
                        ]}

    @valid_school_hku_view %{ "id" => 0, 
                            "adr_city" => @valid_school_hku.adr_city, 
                            "adr_line_1" => @valid_school_hku.adr_line_1, 
                            "adr_line_2" => @valid_school_hku.adr_line_2, 
                            "adr_state" => @valid_school_hku.adr_state, 
                            "adr_zip" => @valid_school_hku.adr_zip, 
                            "is_active_enrollment" => @valid_school_hku.is_active_enrollment, 
                            "is_readonly" => @valid_school_hku.is_readonly, 
                            "name" => @valid_school_hku.name, 
                            "timezone" => @valid_school_hku.timezone}

    @valid_school_bmu_create %{"adr_city" => "Nashville",
                        "adr_line_1" => "555 Church St", 
                        "adr_line_2" => "Suite 100", 
                        "adr_state" => "TN", 
                        "adr_zip" => "37219",
                        "is_active_enrollment" => true,
                        "is_readonly" => true,
                        "name" => "BMU",
                        "timezone" => "-8",
                        "email_domains[0][email_domain]" => "@bmu.edu",
                        "email_domains[0][is_professor_only]" => false,
                        "email_domains[1][email_domain]" => "@bmu1.edu",
                        "email_domains[1][is_professor_only]" => false
                        }

    @valid_school_bmu_view %{ "id" => 0,
                        "adr_city" => @valid_school_bmu.adr_city, 
                        "adr_line_1" => @valid_school_bmu.adr_line_1, 
                        "adr_line_2" => @valid_school_bmu.adr_line_2, 
                        "adr_state" => @valid_school_bmu.adr_state, 
                        "adr_zip" => @valid_school_bmu.adr_zip, 
                        "is_active_enrollment" => @valid_school_bmu.is_active_enrollment, 
                        "is_readonly" => @valid_school_bmu.is_readonly, 
                        "name" => @valid_school_bmu.name, 
                        "timezone" => @valid_school_bmu.timezone}

    @valid_school_bmu_view_domain [%{
           "email_domain" => "@bmu1.edu",
           "is_professor_only" => false 
        },
        %{
            "email_domain" => "@bmu.edu",
            "is_professor_only" => false 
         }]
  
    test "index/2 responds with all Schools", %{jwt: jwt} do
      hku = School.changeset_insert(%School{}, @valid_school_hku)
      |> Repo.insert!
      
      bmu = School.changeset_insert(%School{}, @valid_school_bmu)
      |> Repo.insert!
  
      response = build_conn()
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get(v1_school_path(build_conn(), :index))
      |> json_response(200)
  
      expected = [
        %{@valid_school_hku_view | "id" => hku.id},
        %{@valid_school_bmu_view | "id" => bmu.id}
      ]
  
      assert  response == expected
    end
  
    test "show/2 responds with a schools id if the school is found", %{jwt: jwt} do
      school = School.changeset_insert(%School{}, @valid_school_bmu)
      |> Repo.insert!
  
      response = build_conn()
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> get(v1_school_path(build_conn(), :show, school.id))
      |> json_response(200)
  
      expected = Map.put(%{@valid_school_bmu_view | "id" => school.id}, "email_domains", @valid_school_bmu_view_domain)
  
      assert  response == expected
    end
  
    test "show/2 responds with an error when no school is found", %{jwt: jwt} do
      assert_raise Ecto.NoResultsError, fn ->
          build_conn()
          |> put_req_header("authorization", "Bearer #{jwt}")
          |> get(v1_school_path(build_conn(), :show, 1))
          |> json_response(404)
      end
    end
  
    test "Create/2 creates and responds with a newly created school if attributes are valid", %{jwt: jwt} do
      response = build_conn()
      |> put_req_header("authorization", "Bearer #{jwt}")
      |> put_req_header("content-type", "application/json")
      |> post(v1_school_path(build_conn(), :create, @valid_school_bmu_create))
      |> json_response(200)
  
      assert response["id"] |> is_integer
      assert response["id"] > 0
    end
  
    # test "Create/2 creates and responds with a new school with student if attributes are valid", %{jwt: jwt} do
  
    #   school = Classnavapi.School.changeset_insert(%Classnavapi.School{}, @valid_school_attrs)
    #   |> Repo.insert!
      
    #   student = %{@valid_student_attrs | school_id: school.id}
  
    #   response = build_conn()
    #   |> put_req_header("authorization", "Bearer #{jwt}")
    #   |> post(v1_school_path(build_conn(), :create, Map.put(@valid_school_john, :student, student)))
    #   |> json_response(200)
  
    #   assert response["id"] |> is_integer
    #   assert response["id"] > 0
    #   assert response["student"]["id"] |> is_integer
    #   assert response["student"]["id"] > 0
    # end
  
    # test "Create/2 responds in error if email is invalid for school", %{jwt: jwt} do
      
    #   school = Classnavapi.School.changeset_insert(%Classnavapi.School{}, @valid_school_attrs)
    #   |> Repo.insert!
      
    #   student = %{@valid_student_attrs | school_id: school.id}
  
    #   invalid_school = %{@valid_school_john | email: "test@nottheemaildomain.com"}
  
    #   response = build_conn()
    #   |> put_req_header("authorization", "Bearer #{jwt}")
    #   |> post(v1_school_path(build_conn(), :create, Map.put(invalid_school, :student, student)))
    #   |> json_response(422)
  
    #   expected = %{"errors" => %{"student" => ["Invalid email for school."]}}
      
    #   assert response == expected
    # end
  
    # test "Create/2 responds in error if school does not exist", %{jwt: jwt} do
  
    #   response = build_conn()
    #   |> put_req_header("authorization", "Bearer #{jwt}")
    #   |> post(v1_school_path(build_conn(), :create, Map.put(@valid_school_john, :student, @valid_student_attrs)))
    #   |> json_response(422)
  
    #   expected = %{"errors" => %{"student" => ["Invalid school"]}}
  
    #   assert response == expected
    # end
  
    # test "Create/2 does not create school and returns in error if email is invalid", %{jwt: jwt} do
      
    #   response = build_conn()
    #   |> put_req_header("authorization", "Bearer #{jwt}")
    #   |> post(v1_school_path(build_conn(), :create, %{@valid_school_john | email: "john.com"}))
    #   |> json_response(422)
  
    #   expected = %{"errors" => %{"email" => ["has invalid format"]}}
  
    #   assert response == expected
    # end
  
    # test "Create/2 does not create school and returns in error if required fields are missing", %{jwt: jwt} do
      
    #   response = build_conn()
    #   |> put_req_header("authorization", "Bearer #{jwt}")
    #   |> post(v1_school_path(build_conn(), :create, @invalid_school))
    #   |> json_response(422)
  
    #   expected = %{"errors" => %{"email" => ["can't be blank"], "password" => ["can't be blank"]}}
  
    #   assert response == expected
    # end
  
    # test "Update/2 does not update email and updates other fields when valid", %{jwt: jwt} do
    #   school = School.changeset_insert(%School{}, @valid_school_john)
    #   |> Repo.insert!
  
    #   response = build_conn()
    #   |> put_req_header("authorization", "Bearer #{jwt}")
    #   |> put(v1_school_path(build_conn(), :update, school.id, email: "update@example.com", password: "update"))
    #   |> json_response(200)
  
    #   school_updated = Repo.get(School, response["id"])
  
    #   assert response["id"] |> is_integer
    #   assert response["id"] == school.id
    #   assert response["email"] == @valid_school_john.email
    #   assert response["student"] == nil
    #   assert school_updated.password == "update"
    # end
  
    # test "Update/2 updates students when id is provided", %{jwt: jwt} do
    #   school = Classnavapi.School.changeset_insert(%Classnavapi.School{}, @valid_school_attrs)
    #   |> Repo.insert!
      
    #   student = %{@valid_student_attrs | school_id: school.id}
  
    #   school = School.changeset_insert(%School{}, Map.put(@valid_school_john, :student, student))
    #   |> Repo.insert!
  
    #   response = build_conn()
    #   |> put_req_header("authorization", "Bearer #{jwt}")
    #   |> put(v1_school_path(build_conn(), :update, school.id, student: Map.put(%{student | name_first: "Smashville"}, :id, school.student.id)))
    #   |> json_response(200)
  
    #   assert response["id"] |> is_integer
    #   assert response["id"] == school.id
    #   assert response["student"]["id"] |> is_integer
    #   assert response["student"]["id"] == school.student.id
    #   assert response["student"]["name_first"] == "Smashville"
    # end
  
    # test "Update/2 does not update when required fields missing", %{jwt: jwt} do
    #   school = School.changeset_insert(%School{}, @valid_school_john)
    #   |> Repo.insert!
  
    #   response = build_conn()
    #   |> put_req_header("authorization", "Bearer #{jwt}")
    #   |> put(v1_school_path(build_conn(), :update, school.id, email: "update@example.com", password: ""))
    #   |> json_response(422)
      
    #   expected = %{"errors" => %{"password" => ["can't be blank"]}}
  
    #   assert response == expected
    # end

    test "update/2 responds with an error when no school is found", %{jwt: jwt} do
        assert_raise Ecto.NoResultsError, fn ->
            build_conn()
            |> put_req_header("authorization", "Bearer #{jwt}")
            |> put(v1_school_path(build_conn(), :show, 1))
            |> json_response(404)
        end
      end
  end