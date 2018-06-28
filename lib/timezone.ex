defmodule Timezone do
  use HTTPoison.Base
  
  @timezone_url "http://vip.timezonedb.com/v2/"

  def process_url(url) do
    @timezone_url <> url
  end

  def process_request_options(options) do
    Keyword.merge(options, [params: Map.merge(options[:params], %{key: System.get_env("TZ_API_KEY"), format: "json"})])
  end

  def process_response_body(body) do
    body |> Poison.decode!()
  end
end