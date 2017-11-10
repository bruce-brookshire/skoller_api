defmodule ClassnavapiWeb.Router do
  use ClassnavapiWeb, :router

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
  end

  # Other scopes may use custom stacks.
  scope "/api", ClassnavapiWeb.Api do
    pipe_through :api_auth

    scope "/v1", V1, as: :v1 do
      resources "/users", UserController, only: [:update, :show, :index] do
        post "/roles/:id", User.RoleController, :create
        resources "/roles/", User.RoleController, only: [:index, :delete]
      end
      resources "/roles", RoleController, only: [:show, :index]
      get "/schools/hub", SchoolController, :hub
      resources "/schools", SchoolController, except: [:new, :delete, :edit] do
        resources "/periods", PeriodController, only: [:index, :create]
        resources "/professors", ProfessorController, except: [:new, :delete, :edit]
        resources "/fields-of-study", School.FieldController, except: [:new, :edit, :delete]
      end
      resources "/periods", PeriodController, only: [:update, :show] do
        resources "/classes", ClassController, only: [:create]
      end
      resources "/classes", ClassController, only: [:update, :show, :index] do
        resources "/docs", Class.DocController, only: [:create, :index]
        resources "/assignments", Class.AssignmentController, only: [:create, :index]
        resources "/weights", Class.WeightController, only: [:update, :index]
        post "/confirm", ClassController, :confirm
        post "/help/:id/complete", Class.HelpRequestController, :complete
        post "/help/:class_help_type_id", Class.HelpRequestController, :create
        post "/changes/:id/complete", Class.ChangeRequestController, :complete
        post "/changes/:class_change_type_id", Class.ChangeRequestController, :create
      end
      resources "/students", StudentController, only: [] do
        post "/classes/:class_id", Student.ClassController, :create
        resources "/classes", Student.ClassController, only: [:show] do
          resources "/grades", Student.Class.GradeController, only: [:create, :index]
        end
        resources "/fields", Student.FieldController, only: [:create, :delete, :index]
      end
      resources "/class-statuses", Class.StatusController, only: [:index]
      get "/class-statuses/hub", Class.StatusController, :hub
      resources "/class-help-types", Class.Help.TypeController, only: [:index]
      resources "/class-change-types", Class.Change.TypeController, only: [:index]
    end
  end

  scope "/api", ClassnavapiWeb.Api do
    pipe_through :api

    scope "/v1", V1, as: :v1 do
      post "/users/login", AuthController, :create
      resources "/users", UserController, only: [:create]
    end
  end
end
