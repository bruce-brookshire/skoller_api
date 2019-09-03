defmodule Skoller.Services.SesMailer do
  import ExAws.SES

  @sending_env System.get_env("MIX_ENV")

  @type user_template_data :: %{to: binary, form: Map}

  @spec send_batch_email(users :: list(user_template_data), template_name :: binary) :: atom
  def send_batch_email(users, template_name) do
    IO.inspect(users)

    template_data = users |> Enum.map(&render_template_data/1)

    template_name
    |> send_bulk_templated_email("support@skoller.co", template_data)
    |> send
  end

  @spec send_individual_email(user :: user_template_data, template_name :: binary) :: atom
  def send_individual_email(%{to: email_address, form: template_data}, template_name) do
    case Poison.encode(template_data) do
      {:ok, template_string} ->
        %{to: email_address}
        |> send_templated_email(
          "support@skoller.co",
          template_name,
          template_string
        )
        |> send

      error ->
        require Logger
        Logger.error(error)
    end
  end

  @spec send(ExAws.Operation.Query.t()) :: :ok
  defp send(email) do
    if @sending_env == :prod do
      email |> ExAws.request()
    end
  end

  defp render_template_data(%{to: email_address, form: replacement_data}),
    do: %{destination: %{to: email_address}, replacement_template_data: replacement_data}
end
