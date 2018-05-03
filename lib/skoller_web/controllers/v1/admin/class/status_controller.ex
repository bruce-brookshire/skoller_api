defmodule SkollerWeb.Api.V1.Admin.Class.StatusController do
    use SkollerWeb, :controller

    alias Skoller.Repo
    alias SkollerWeb.ClassView
    alias Skoller.Class.Lock
    alias SkollerWeb.Helpers.RepoHelper
    alias Skoller.Mailer
    alias Skoller.Classes
    alias Skoller.Users

    import SkollerWeb.Helpers.AuthPlug
    import Ecto.Query
    import Bamboo.Email
    
    @admin_role 200
    @help_role 500

    @syllabus_status 200
    @assignment_status 400
    @review_status 500
    @help_status 600

    @weight_lock 100
    @assignment_lock 200
    @review_lock 300

    @from_email "support@skoller.co"
    @syllabus_subj "Wrong Syllabus?"
    @syllabus_greeting "Hi there,"
 
    @wrong_syllabus_submitted "Our team has noticed that the wrong syllabus was submitted for "
    @no_biggie ". No biggie, we all goof up every now and then!"
    @we_deleted_it " We deleted the wrong syllabus."
    @you_should " You should now be able to "
    @sign_in "sign in"
    @upload_correct_syllabus " and upload the correct syllabus when you're ready!"
    @syllabus_ending "We hope you and your classmates have a great semester!"
    
    plug :verify_role, %{roles: [@admin_role, @help_role]}

    def update(conn, %{"class_id" => class_id, "class_status_id" => id}) do
      old_class = Classes.get_class_by_id!(class_id)
      |> Repo.preload(:class_status)

      status = Classes.get_status_by_id!(id)

      changeset = old_class
      |> Ecto.Changeset.change(%{class_status_id: id})
      |> compare_class_status_completion(old_class.class_status.is_complete, status.is_complete)

      multi = Ecto.Multi.new()
      |> Ecto.Multi.update(:class, changeset)
      |> Ecto.Multi.run(:class_locks, &reset_locks(&1.class, status))

      case Repo.transaction(multi) do
        {:ok, %{class: %{class_status_id: @syllabus_status} = class}} ->
          Users.get_users_in_class(class.id)
          |> Enum.each(&send_need_syllabus_email(&1, class))
          render(conn, ClassView, "show.json", class: class)
        {:ok, %{class: class}} ->
          Classes.evaluate_class_completion(old_class, class)
          render(conn, ClassView, "show.json", class: class)
        {:error, _, failed_value, _} ->
          conn
          |> RepoHelper.multi_error(failed_value)
      end
    end

    defp send_need_syllabus_email(user, class) do
      user = user |> Repo.preload(:student)
      new_email()
      |> to(user.email)
      |> Bamboo.Email.from(@from_email)
      |> subject(@syllabus_subj)
      |> html_body(syllabus_html_body(class))
      |> text_body(syllabus_text_body(class))
      |> Mailer.deliver_later
    end

    defp syllabus_html_body(class) do
      "<p>" <> @syllabus_greeting <> "<br />" <>
      "<br />" <>
      @wrong_syllabus_submitted <> class.name <> @no_biggie <> @we_deleted_it <> @you_should <>
      "<a href=" <> to_string(System.get_env("WEB_URL")) <> ">" <> @sign_in <> "</a>" <>
      @upload_correct_syllabus <> "<br />" <>
      "<br />" <>
      @syllabus_ending <> "</p>" <> 
      Mailer.signature()
    end

    defp syllabus_text_body(class) do
      @syllabus_greeting <> "\n" <>
      "\n" <>
      @wrong_syllabus_submitted <> class.name <> @no_biggie <> @we_deleted_it <> @you_should <> @sign_in <> @upload_correct_syllabus <> "\n" <>
      "\n" <>
      @syllabus_ending <> "\n" <>
      "\n" <>
      Mailer.text_signature()
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