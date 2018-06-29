defmodule Skoller.AdminClasses do
  @moduledoc """
  A context module for class administration
  """

  alias Skoller.Repo
  alias Skoller.Mailer
  alias Skoller.Classes
  alias Skoller.Users
  alias Skoller.Locks

  import Bamboo.Email

  @syllabus_status 200
  
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

  @doc """
  Updates a class status as an administrator.

  This bypasses a lot of protections of other methods of changing a class.
  Because of this, there are some after effects of the change.

  ## Behavior
   * A class cannot be moved from a status considered complete, to an incomplete status.
   * If a class is moved to a lower status, any locks will be destroyed (down to the new status).
   * If a class is moved back to needs syllabus, it will email students in an attempt to re-upload.
   * If a class is completed, `Classes.evaluate_class_completion/2` is called.

  ## Returns
  `{:ok, Map}` or `{:error, _, _, _}` where `Map` is a map containing:
   * `{:class, Skoller.Classes.Class}`
   * `{:class_locks, Tuple}`
  """
  def update_status(class_id, status_id) do
    old_class = Classes.get_class_by_id!(class_id)
    |> Repo.preload(:class_status)

    status = Classes.get_status_by_id!(status_id)

    changeset = old_class
    |> Ecto.Changeset.change(%{class_status_id: status_id})
    |> compare_class_status_completion(old_class.class_status.is_complete, status.is_complete)

    multi = Ecto.Multi.new()
    |> Ecto.Multi.update(:class, changeset)
    |> Ecto.Multi.run(:class_locks, &Locks.delete_locks(&1.class, status))
    |> Repo.transaction()

    case multi do
      {:ok, %{class: %{class_status_id: @syllabus_status} = class}} ->
        Users.get_users_in_class(class.id)
        |> Enum.each(&send_need_syllabus_email(&1, class))
      {:ok, %{class: class}} ->
        Classes.evaluate_class_completion(old_class, class)
      _ -> nil
    end

    multi
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

  defp compare_class_status_completion(changeset, true, false) do
    changeset
    |> Ecto.Changeset.add_error(:class_status_id, "Class status moving from complete to incomplete")
  end
  defp compare_class_status_completion(changeset, _, _), do: changeset
end