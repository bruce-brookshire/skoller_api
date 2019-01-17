defmodule SkollerWeb.Router do
  @moduledoc """
  Routes requests to the appropriate controller.
  """
  use SkollerWeb, :router

  import SkollerWeb.Plugs.Auth

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :sns do
    plug :accepts, ["json", "text"]
  end

  pipeline :api_auth_verified do
    plug :accepts, ["json"]
    plug Guardian.Plug.Pipeline, module: Skoller.Auth,
                                  error_handler: Skoller.AuthErrorHandler
    plug Guardian.Plug.VerifyHeader, realm: "Bearer"
    plug Guardian.Plug.EnsureAuthenticated
    plug Guardian.Plug.LoadResource
    plug :authenticate
    plug :is_phone_verified
  end

  pipeline :api_auth do
    plug :accepts, ["json"]
    plug Guardian.Plug.Pipeline, module: Skoller.Auth,
                                  error_handler: Skoller.AuthErrorHandler
    plug Guardian.Plug.VerifyHeader, realm: "Bearer"
    plug Guardian.Plug.EnsureAuthenticated
    plug Guardian.Plug.LoadResource
    plug :authenticate
  end

  if Mix.env == :dev do
    forward "/sent_emails", Bamboo.SentEmailViewerPlug
  end

  # Other scopes may use custom stacks.
  scope "/api", SkollerWeb.Api do
    pipe_through :api_auth_verified

    scope "/v1", V1, as: :v1 do
      resources "/organizations", OrganizationController, only: [:index]
      resources "/organizations", Admin.OrganizationController, except: [:new, :edit, :index]

      get "/email_domains/:email_domain/check", School.EmailDomainController, :show
      resources "/email-types", Admin.EmailTypeController, only: [:index, :update]

      get "/sammi", SammiController, :status
      post "/sammi/train", SammiController, :train

      post "/schools/csv", CSVController, :school

      get "/four-door/overrides", Admin.School.FourDoorController, :index
      get "/four-door", Admin.FourDoorController, :index
      put "/four-door", Admin.FourDoorController, :update

      get "/chat-sort-algorithms", Chat.SortAlgorithmController, :index

      post "/enrollment-link/:token", Student.ClassController, :link

      # Login/out routes
      post "/logout", AuthController, :logout
      post "/reset", ForgotEmailController, :reset

      # Auto Update Routes
      resources "/auto-updates", Admin.AutoUpdateController, only: [:index]
      put "/auto-updates", Admin.AutoUpdateController, :update
      get "/auto-updates/forecast", Admin.AutoUpdateController, :forecast

      # Min Ver Routes
      put "/min-version", Admin.MinVerController, :update

      # Location Routes
      get "/locations", LocationController, :index

      # Analytics routes
      get "/analytics", Analytics.AnalyticsController, :index

      # User routes
      post "/users/create", Admin.UserController, :create
      put "/users/:user_id/update", Admin.UserController, :update
      get "/users/csv", Admin.UserController, :csv
      resources "/users", Admin.UserController, only: [:show, :index] do
        # User Role routes
        post "/roles/:id", Admin.User.RoleController, :create
        resources "/roles/", Admin.User.RoleController, only: [:index, :delete]
        post "/report", ReportUserController, :create
      end

      post "/report/:id/complete", Admin.ReportUserController, :complete
      get "/report", Admin.ReportUserController, :index

      # Role routes
      resources "/roles", RoleController, only: [:show, :index]

      # School routes
      get "/schools/hub", Admin.SchoolController, :hub
      get "/school/list", SchoolController, :index
      resources "/schools", SchoolController, only: [:create]
      resources "/schools", Admin.SchoolController, only: [:update, :show, :index] do

        post "/four-door", Admin.School.FourDoorController, :school
        delete "/four-door", Admin.School.FourDoorController, :delete

        # School Professor routes
        resources "/professors", ProfessorController, only: [:create, :index]

        get "/classes", School.ClassController, :index
        get "/classes/min", School.ClassController, :index_min

        # School Period routes
        resources "/periods", PeriodController, only: [:index, :create]

        resources "/email_domains", EmailDomainController, only: [:index, :create]
      end
      resources "/email_domains", EmailDomainController, only: [:show, :update, :delete]

      # Class Period routes
      resources "/periods", Admin.PeriodController, only: [:update, :show] do
        # Class Period Class routes
        resources "/classes", ClassController, only: [:create]
        post "/classes/csv", CSVController, :class
      end

      get "/periods/:period_id/classes", ClassController, :index

      # Class routes
      resources "/class-statuses", Class.StatusController, only: [:index]
      get "/class-statuses/hub", Class.StatusController, :hub
      post "/classes/:class_hash/pydocs", Admin.Class.ScriptDocController, :create
      get "/classes/:id", NonMemberClassController, :show
      get "/classes/:id/admin", Admin.ClassController, :show
      
      resources "/classes", ClassController, only: [:update, :index] do

        post "/notes", Class.NoteController, :create

        put "/statuses", Admin.Class.StatusController, :update

        # Chat routes
        resources "/posts", Admin.Class.ChatPostController, only: [:index, :delete, :show]
        resources "/posts", Class.ChatPostController, only: [:create, :update] do
          resources "/comments", Class.ChatCommentController, only: [:create]
          resources "/like", Class.Chat.PostLikeController,  only: [:create]
          delete "/unlike", Class.Chat.PostLikeController, :delete
          resources "/star", Class.Chat.PostStarController, only: [:create]
          delete "/unstar", Class.Chat.PostStarController, :delete
          post "/read", Class.Chat.PostStarController, :update
        end
        put "/comments/:id", Class.ChatCommentController, :update
        resources "/comments", Admin.Class.ChatCommentController, only: [:delete] do
          resources "/replies", Class.ChatReplyController, only: [:create]
          resources "/star", Class.Chat.CommentStarController, only: [:create]
          delete "/unstar", Class.Chat.CommentStarController, :delete
          resources "/like", Class.Chat.CommentLikeController, only: [:create]
          delete "/unlike", Class.Chat.CommentLikeController, :delete
        end
        resources "/replies", Admin.Class.ChatReplyController, only: [:delete] do
          resources "/like", Class.Chat.ReplyLikeController, only: [:create]
          delete "/unlike", Class.Chat.ReplyLikeController, :delete
        end
        put "/replies/:id", Class.ChatReplyController, :update

        # Class Lock routes
        post "/lock", Class.LockController, :lock
        post "/lock/weights", Class.LockController, :weights
        post "/lock/assignments", Class.LockController, :assignments
        post "/unlock", Class.LockController, :unlock
        get "/locks", Class.LockController, :index

        # Class Doc routes
        resources "/docs", Class.DocController, only: [:create, :index]
        delete "/docs/:id", Admin.Class.DocController, :delete

        # Class Assignment routes
        resources "/assignments", Class.AssignmentController, only: [:create, :index]

        # Class Weight routes
        resources "/weights", Class.WeightController, only: [:index]
        resources "/weights", Admin.Class.WeightController, only: [:create]

        # Class Request routes
        post "/help/:class_help_type_id", Class.HelpRequestController, :create
        post "/changes/:class_change_type_id", Class.ChangeRequestController, :create
        post "/student-request/:class_student_request_type_id", Class.StudentRequestController, :create
      end
      post "/changes/:id/complete", Admin.Class.ChangeRequestController, :complete
      post "/student-requests/:id/complete", Admin.Class.StudentRequestController, :complete
      resources "/class-help-types", Class.Help.TypeController, only: [:index]
      resources "/class-change-types", Class.Change.TypeController, only: [:index]
      resources "/class-student-request-types", Class.StudentRequest.TypeController, only: [:index]

      # Student routes
      resources "/students", StudentController, only: [] do
        get "/student-link/:token", StudentController, :show
        resources "/fields", Student.FieldController, only: [:create, :delete]

        # Chat routes
        get "/chat", Student.ChatController, :chat
        get "/inbox", Student.ChatController, :inbox

        # Notificaiton route
        get "/notifications", Student.NotificationController, :notifications

        #Text Verification routes
        post "/verify", Student.VerificationController, :verify
        post "/resend", Student.VerificationController, :resend

        # Student Class routes
        post "/mods/:id", Student.ModController, :create
        get "/mods", Student.ModController, :index
        get "/mods/:id", Student.ModController, :show
        post "/classes/:class_id", Student.ClassController, :create
        delete "/classes/:class_id", Student.ClassController, :delete
        put "/classes/:class_id", Student.ClassController, :update
        get "/classes/:class_id/speculate", Student.Class.SpeculateController, :speculate
        resources "/assignments", Student.Class.AssignmentController, only: [:index]
        get "/classes", Admin.Student.ClassController, :index
        get "/classes/:class_id", Student.ClassController, :show
        get "/classes/:class_id/mods", Student.Class.ModController, :index
        resources "/classes/:class_id/assignments", Student.Class.AssignmentController, only: [:create]

        # School routes
        get "/school", Student.SchoolController, :show
      end

      # Assignment routes
      resources "/class/assignments", Class.AssignmentController, only: [:delete, :update]
      resources "/assignments", Student.Class.AssignmentController, only: [:delete, :update, :show] do

        # Assignment Post routes
        resources "/posts", Admin.Assignment.PostController, only: [:delete]
        resources "/posts", Assignment.PostController, only: [:create, :update]

        # Assignment Grade routes
        resources "/grades", Student.Class.GradeController, only: [:create]
        put "/grades", Student.Class.GradeController, :create

        # Class Mod routes
        get "/mods", Assignment.ModController, :index
      end

      # Weight routes
      resources "/weights", Admin.Class.WeightController, only: [:update, :delete]

      # Professor routes
      resources "/professors", ProfessorController, only: [:show]
      resources "/professors", Admin.ProfessorController, only: [:update]

      # Field of Study routes
      resources "/fields-of-study", Admin.FieldController, only: [:update, :create, :index]
      post "/fields-of-study/csv", CSVController, :fos

      #Syllabus Worker routes
      post "/syllabus-workers", SyllabusWorkerController, :class

      post "/notifications/syllabus-needed", NotificationController, :syllabus
      post "/notifications/custom", NotificationController, :custom
      get "/notifications", NotificationController, :index

      resources "/reminder-messages", Assignment.ReminderController, only: [:create, :index, :delete]
      resources "/reminder-messages/topics", Assignment.Reminder.TopicController, only: [:index]

      resources "/custom-links", CustomLinkController, only: [:create, :index, :update, :show]
    end
  end

  scope "/api", SkollerWeb.Api do
    pipe_through :api_auth

    scope "/v1", V1, as: :v1 do
      put "/users/:user_id", UserController, :update
      post "/users/:user_id/register", DeviceController, :register
      post "/users/token-login", AuthController, :token
    end
  end

  scope "/api", SkollerWeb.Api do
    pipe_through :sns

    post "/bounce", BounceController, :bounce
  end

  scope "/api", SkollerWeb.Api do
    pipe_through :api

    scope "/v1", V1, as: :v1 do
      post "/users/login", AuthController, :login
      resources "/users", NewUserController, only: [:create]
      put "/users/:user_id/email-preferences", EmailPreferenceController, :update
      get "/users/:user_id/email-preferences", EmailPreferenceController, :index
      resources "/fields-of-study/list", FieldController, only: [:index]
      post "/forgot", ForgotEmailController, :forgot
      get "/min-version", MinVerController, :index
      get "/enrollment-link/:token", Student.Class.LinkController, :show
      get "/email-types/list", EmailTypeController, :index
    end
  end
end
