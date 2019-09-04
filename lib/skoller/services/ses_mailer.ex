defmodule Skoller.Services.SesMailer do
  import ExAws.SES
  require Logger

  @sending_env System.get_env("MIX_ENV")

  @type user_template_data :: %{to: binary, form: Map}

  @spec send_batch_email(users :: list(user_template_data), template_name :: binary) :: atom
  def send_batch_email([], _), do: :ok

  def send_batch_email(users, template_name) do
    template_data = users |> Enum.map(&render_template_data/1)

    IO.inspect(users)

    template_name
    |> send_bulk_templated_email("Skoller <support@skoller.co>", template_data,
      reply_to: ["noreply@skoller.co"]
    )
    |> IO.inspect()
    |> send
  end

  @spec send_individual_email(user :: user_template_data, template_name :: binary) :: atom
  def send_individual_email(%{to: email_address, form: template_data}, template_name) do
    %{to: [email_address]}
    |> send_templated_email(
      "Skoller <support@skoller.co>",
      template_name,
      template_data,
      reply_to: ["noreply@skoller.co"]
    )
    |> send
  end

  @spec send(ExAws.Operation.Query.t()) :: :ok
  defp send(email) do
    if @sending_env == "prod" do
      email
      |> ExAws.request()
      |> process_response
    end
  end

  defp process_response({:error, term}), do: IO.inspect(term)
  defp process_response(_), do: :ok

  defp render_template_data(%{to: email_address, form: replacement_data}),
    do: %{destination: %{to: [email_address]}, replacement_template_data: replacement_data}
end
