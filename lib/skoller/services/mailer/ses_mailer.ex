defmodule Skoller.Services.Mailer.AwsEmailAdapter do
  import ExAws.SES
  alias Skoller.EmailJobs.EmailJob

  @sending_env System.get_env("MIX_ENV")

  @type user_template_data :: %{to: binary, form: Map}

  @spec send_batch_email(users :: list(user_template_data), template_name :: binary) :: atom
  def send_batch_email(users, template_name) do
    template_data = users |> Enum.map(&render_template_data/1)

    template_name
    |> send_bulk_templated_email("support@skoller.co", template_data)
    |> send
  end

  @spec send_individual_email(user :: user_template_data, template_name :: binary) :: atom
  def send_individual_email(%{to: email_address, form: replacement_data}, template_name) do
    %{to: email_address}
    |> send_templated_email(
      "support@skoller.co",
      template_name,
      replacement_data |> Poison.encode()
    )
    |> send
  end

  @spec send(ExAws.Operation.Query.t()) :: :ok
  defp send(email)
       when @sending_env == "prod",
       do: email |> ExAws.request()

  defp send(_)

  defp render_template_data(%{to: email_address, form: replacement_data}),
    do: %{destination: %{to: email_address}, replacement_template_data: replacement_data}
end
