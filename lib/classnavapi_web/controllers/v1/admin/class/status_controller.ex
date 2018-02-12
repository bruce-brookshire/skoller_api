defmodule ClassnavapiWeb.Api.V1.Admin.Class.StatusController do
    use ClassnavapiWeb, :controller

    alias Classnavapi.Class
    alias Classnavapi.Class.Status
    alias Classnavapi.Repo
    alias ClassnavapiWeb.ClassView
    alias Classnavapi.Class.Lock
    alias ClassnavapiWeb.Helpers.RepoHelper
    alias ClassnavapiWeb.Helpers.NotificationHelper
    alias ClassnavapiWeb.Helpers.StatusHelper
    alias Classnavapi.Mailer
    alias Classnavapi.User
    alias Classnavapi.Class.StudentClass

    import ClassnavapiWeb.Helpers.AuthPlug
    import Ecto.Query
    import Bamboo.Email
    
    @admin_role 200
    @help_role 500

    @new_class_status 100
    @assignment_status 400
    @review_status 500
    @help_status 600
    @complete_status 700

    @weight_lock 100
    @assignment_lock 200
    @review_lock 300

    @from_email "support@skoller.co"
    @deny_subj " has been denied"
    @greeting "Hi "
    @comma ","
    @ending "Thank you"

    @your_request "Your request to create a new class, "
    @has_been_denied "has been denied. "
    @reason "The reason is because that class already exists at your school or the request is illegitimate. Please contact us at support@skoller.co for further assistance."
    
    plug :verify_role, %{roles: [@admin_role, @help_role]}

    def approve(conn, %{"class_id" => class_id}) do
      class = Class
      |> Repo.get!(class_id)

      updated = class
      |> StatusHelper.check_status(nil)

      case updated do
        {:ok, nil} ->
          render(conn, ClassView, "show.json", class: class)
        {:ok, class} ->
          render(conn, ClassView, "show.json", class: class)
        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
      end
    end

    def deny(conn, %{"class_id" => class_id}) do
      class = Class
      |> Repo.get!(class_id)

      conn |> deny_class(class)
    end

    def update(conn, %{"class_id" => class_id, "class_status_id" => id}) do
      old_class = Repo.get!(Class, class_id)
      |> Repo.preload(:class_status)

      status = Repo.get!(Status, id)

      changeset = old_class
      |> Ecto.Changeset.change(%{class_status_id: id})
      |> compare_class_status_completion(old_class.class_status.is_complete, status.is_complete)

      multi = Ecto.Multi.new()
      |> Ecto.Multi.update(:class, changeset)
      |> Ecto.Multi.run(:class_locks, &reset_locks(&1.class, status))

      case Repo.transaction(multi) do
        {:ok, %{class: %{class_status_id: @complete_status} = class}} ->
          if old_class.class_status.is_complete == false do
            Task.start(NotificationHelper, :send_class_complete_notification, [class])
          end
          render(conn, ClassView, "show.json", class: class)
        {:ok, %{class: class}} ->
          render(conn, ClassView, "show.json", class: class)
        {:error, _, failed_value, _} ->
          conn
          |> RepoHelper.multi_error(failed_value)
      end
    end

    defp deny_class(conn, %Class{class_status_id: @new_class_status} = class) do
      users = from(u in User)
      |> join(:inner, [u], sc in StudentClass, sc.student_id == u.student_id)
      |> where([u, sc], sc.class_id == ^class.id and sc.is_dropped == false)
      |> Repo.all()

      case Repo.delete(class) do
        {:ok, _struct} ->
          users |> Enum.each(&send_deny_email(&1, class))
          conn
          |> send_resp(200, "")
        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> render(ClassnavapiWeb.ChangesetView, "error.json", changeset: changeset)
      end
    end
    defp deny_class(conn, _class), do: conn |> send_resp(422, "")

    defp send_deny_email(user, class) do
      user = user |> Repo.preload(:student)
      new_email()
      |> to(user.email)
      |> Bamboo.Email.from(@from_email)
      |> subject(class.name <> @deny_subj)
      |> html_body(deny_html_body(class, user))
      |> text_body(deny_text_body(class, user))
      |> Mailer.deliver_later
    end

    defp deny_html_body(class, user) do
      "<p>" <> @greeting <> user.student.name_first <> @comma <>  "<br />" <>
      "<br />" <>
      @your_request <> class.name <> @has_been_denied <> @reason <> "<br />" <>
      "<br />" <>
      @ending <> "</p>"
    end

    defp deny_text_body(class, user) do
      @greeting <> user.student.name_first <> @comma <>  "\n" <>
      "\n" <>
      @your_request <> class.name <> @has_been_denied <> @reason <> "\n" <>
      "\n" <>
      @ending
    end

    defp reset_locks(_class, %{is_complete: true}), do: {:ok, nil}
    defp reset_locks(%{class_status_id: @help_status}, _status), do: {:ok, nil}
    defp reset_locks(class, _status) do
      case class.class_status_id do
        @review_status -> 
          {:ok, delete_locks(class, @review_lock)}
        @assignment_status ->
          {:ok, delete_locks(class, @assignment_lock)}
        _ ->
          {:ok, delete_locks(class, @weight_lock)}
      end
    end

    defp delete_locks(class, lock_type_min) do
      from(l in Lock)
      |> where([l], l.class_id == ^class.id and l.class_lock_section_id >= ^lock_type_min)
      |> Repo.delete_all()
    end

    defp compare_class_status_completion(changeset, true, false) do
      changeset
      |> Ecto.Changeset.add_error(:class_status_id, "Class status moving from complete to incomplete")
    end
    defp compare_class_status_completion(changeset, _, _), do: changeset
  end