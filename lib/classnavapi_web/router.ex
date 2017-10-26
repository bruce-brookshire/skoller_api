defmodule ClassnavapiWeb.Router do
  use ClassnavapiWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

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

  scope "/", ClassnavapiWeb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  scope "/api", ClassnavapiWeb.Api do
    pipe_through :api_auth

    scope "/v1", V1, as: :v1 do
      resources "/users", UserController, except: [:new,:delete,:edit] do
        post "/roles/:id", RoleController, :create
        resources "/roles/", RoleController, only: [:index,:delete]
      end
      resources "/schools", SchoolController, except: [:new,:delete,:edit] do
        resources "/periods", PeriodController, except: [:new,:delete,:edit]
        resources "/professors", ProfessorController, except: [:new,:delete,:edit]
        resources "/classes", ClassController, except: [:new,:delete,:edit] do
          resources "/docs", Class.DocController, only: [:create,:index]
          resources "/assignments", Class.AssignmentController, only: [:create,:index]
        end
      end
      resources "/class-statuses", Class.StatusController, only: [:index]
    end
  end

  scope "/api", ClassnavapiWeb.Api do
    pipe_through :api

    scope "/v1", V1, as: :v1 do
      post "/users/login", AuthController, :create
    end
  end
end
