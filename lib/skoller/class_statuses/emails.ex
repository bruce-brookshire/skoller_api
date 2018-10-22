defmodule Skoller.ClassStatuses.Emails do
  @moduledoc """
  A context module for class status emails.
  """

  alias Skoller.Services.Mailer
  alias Skoller.StudentClasses.Users
  alias Skoller.Services.Email

  import Bamboo.Email

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
  Sends an email to students when a class status is changed needs syllabus.
  """
  def send_need_syllabus_email(class) do
    Users.get_users_in_class(class.id)
    |> Enum.each(&build_need_syllabus_email(&1, class))
  end

  defp build_need_syllabus_email(class, user) do
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
    Email.signature()
  end

  defp syllabus_text_body(class) do
    @syllabus_greeting <> "\n" <>
    "\n" <>
    @wrong_syllabus_submitted <> class.name <> @no_biggie <> @we_deleted_it <> @you_should <> @sign_in <> @upload_correct_syllabus <> "\n" <>
    "\n" <>
    @syllabus_ending <> "\n" <>
    "\n" <>
    Email.text_signature()
  end
end