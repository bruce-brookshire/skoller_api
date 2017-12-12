defmodule ClassnavapiWeb.Router do
  use ClassnavapiWeb, :router

  import ClassnavapiWeb.Helpers.AuthPlug

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_auth do
    plug :accepts, ["json"]
    plug Guardian.Plug.Pipeline, module: Classnavapi.Auth,
                                  error_handler: Classnavapi.AuthErrorHandler
    plug Guardian.Plug.VerifyHeader, realm: "Bearer"
    plug Guardian.Plug.EnsureAuthenticated
    plug Guardian.Plug.LoadResource
    plug :authenticate
  end

  # Other scopes may use custom stacks.
  scope "/api", ClassnavapiWeb.Api do
    pipe_through :api_auth

    scope "/v1", V1, as: :v1 do
      post "/logout", AuthController, :logout
      post "/users/token-login", AuthController, :token

      # User routes
      put "/users/:user_id", UserController, :update
      resources "/users", Admin.UserController, only: [:show, :index] do
        #Device routes
        post "/register", DeviceController, :register

        # User Role routes
        post "/roles/:id", Admin.User.RoleController, :create
        resources "/roles/", Admin.User.RoleController, only: [:index, :delete]
      end

      # Role routes
      resources "/roles", RoleController, only: [:show, :index]

      # School routes
      get "/schools/hub", Admin.SchoolController, :hub
      resources "/schools", Admin.SchoolController, only: [:create, :update, :show, :index] do

        # School Period routes
        resources "/periods", PeriodController, only: [:index, :create]

        # School Field of Study routes
        resources "/fields-of-study", Admin.School.FieldController, only: [:create, :index]
      end

      # Class Period routes
      resources "/periods", PeriodController, only: [:update, :show] do

        # Class Period Professor routes
        resources "/professors", ProfessorController, only: [:create, :index]

        # Class Period Class routes
        resources "/classes", ClassController, only: [:create]
      end

      # Class routes
      resources "/class-statuses", Class.StatusController, only: [:index]
      get "/class-statuses/hub", Class.StatusController, :hub
      resources "/classes", ClassController, only: [:update, :show, :index] do
        put "/statuses", Class.StatusController, :update
        post "/confirm", ClassController, :confirm

        # Class Lock routes
        post "/lock", Class.LockController, :lock
        post "/unlock", Class.LockController, :unlock

        # Class Doc routes
        resources "/docs", Class.DocController, only: [:create, :index]

        # Class Assignment routes
        resources "/assignments", Class.AssignmentController, only: [:create, :index]

        # Class Weight routes
        resources "/weights", Class.WeightController, only: [:index]
        resources "/weights", Admin.Class.WeightController, only: [:create]

        # Class Request routes
        post "/help/:class_help_type_id", Class.HelpRequestController, :create
        post "/changes/:class_change_type_id", Class.ChangeRequestController, :create
      end
      post "/help/:id/complete", Admin.Class.HelpRequestController, :complete
      post "/changes/:id/complete", Admin.Class.ChangeRequestController, :complete
      resources "/class-help-types", Class.Help.TypeController, only: [:index]
      resources "/class-change-types", Class.Change.TypeController, only: [:index]

      # Student routes
      resources "/students", StudentController, only: [] do
        resources "/fields", Student.FieldController, only: [:create, :delete]

        #Text Verification routes
        post "/verify", Student.VerificationController, :verify
        post "/resend", Student.VerificationController, :resend

        # Student Class routes
        post "/mods/:id", Student.ModController, :create
        post "/classes/:class_id", Student.ClassController, :create
        delete "/classes/:class_id", Student.ClassController, :delete
        put "/classes/:id", Student.ClassController, :update
        get "/classes/:class_id/speculate", Student.Class.SpeculateController, :speculate
        resources "/assignments", Student.Class.AssignmentController, only: [:index]
        resources "/classes", Student.ClassController, only: [:show, :index] do
          get "/mods", Student.Class.ModController, :index
          resources "/assignments", Student.Class.AssignmentController, only: [:create]
        end
      end

      # Assignment routes
      resources "/class/assignments", Class.AssignmentController, only: [:delete]
      resources "/assignments", Student.Class.AssignmentController, only: [:delete, :update, :show] do

        # Assignment Grade routes
        resources "/grades", Student.Class.GradeController, only: [:create]
        put "/grades", Student.Class.GradeController, :create
      end

      # Weight routes
      resources "/weights", Admin.Class.WeightController, only: [:update, :delete]

      # Professor routes
      resources "/professors", ProfessorController, only: [:show]
      resources "/professors", Admin.ProfessorController, only: [:update]

      # Field of Study routes
      resources "/fields-of-study", Admin.School.FieldController, only: [:update]
      resources "/fields-of-study", School.FieldController, only: [:show]

      #Syllabus Worker routes
      post "/syllabus-workers/weights", SyllabusWorkerController, :weights
      post "/syllabus-workers/assignments", SyllabusWorkerController, :assignments
      post "/syllabus-workers/reviews", SyllabusWorkerController, :reviews
    end
  end

  scope "/api", ClassnavapiWeb.Api do
    pipe_through :api

    scope "/v1", V1, as: :v1 do
      post "/users/login", AuthController, :login
      resources "/users", NewUserController, only: [:create]
      get "/school/list", SchoolController, :index
      resources "/schools/:school_id/fields-of-study/list", School.FieldController, only: [:index]
    end
  end
end
