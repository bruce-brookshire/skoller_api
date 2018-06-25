defmodule Sammi do
  use HTTPoison.Base

  def process_url(url) do
    to_string(System.get_env("SAMMI_URL")) <> url
  end

  def process_response_body(""), do: ""
  def process_response_body(body) do
    body |> Poison.decode!()
  end
end