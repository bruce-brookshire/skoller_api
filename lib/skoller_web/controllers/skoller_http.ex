defmodule SkollerWeb.HttpRequest do
  alias SkollerWeb.HttpRequest

  @body_methods [:post, :put]

  @enforce_keys [:method]
  defstruct [:url, :body, :method, :headers, :params]

  # HTTP Methods
  def get, do: %HttpRequest{method: :get}
  def post, do: %HttpRequest{method: :post}
  def put, do: %HttpRequest{method: :put}
  def delete, do: %HttpRequest{method: :delete}

  # Constructing request
  def add_url(%HttpRequest{} = request, url) when is_binary(url), do: %{request | url: url}

  def add_headers(%HttpRequest{} = request, headers) when is_list(headers),
    do: %{request | headers: headers}

  def add_body(%HttpRequest{method: method} = request, body)
      when (is_map(body) or is_list(body)) and method in @body_methods,
      do: %{request | body: body}

  def add_params(%HttpRequest{} = request, params), do: %{request | params: params}

  # Sending request
  def send_request(%HttpRequest{method: :get, url: url, headers: headers}),
    do: HTTPoison.get(url, headers)

  def send_request(%HttpRequest{method: :delete, url: url, headers: headers, params: params}),
    do: HTTPoison.delete(url, headers, params: params)

  def send_request(%HttpRequest{
        method: method,
        url: url,
        headers: headers,
        body: body
      })
      when method in @body_methods do
    case Poison.encode(body || "") do
      {:ok, encoded_body} ->
        Kernel.apply(HTTPoison, method, [url, encoded_body, headers])

      error ->
        error
    end
  end

  def send_request(%HttpRequest{method: method}),
    do: raise(("Invalid method: " <> method) |> to_string())
end
