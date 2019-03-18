defmodule HTTP.Response do
  defstruct status_code: nil, headers: nil, body: [], complete?: false

  def parse(mint_messages, request_ref, http_response \\ %__MODULE__{})

  def parse(
        [{:status, request_ref, status_code} | mint_messages],
        request_ref,
        http_response = %HTTP.Response{}
      ) do
    parse(mint_messages, request_ref, %{http_response | status_code: status_code})
  end

  def parse(
        [{:headers, request_ref, headers} | mint_messages],
        request_ref,
        http_response = %HTTP.Response{}
      ) do
    parse(mint_messages, request_ref, %{http_response | headers: headers})
  end

  def parse(
        [{:data, request_ref, data} | mint_messages],
        request_ref,
        http_response = %HTTP.Response{}
      ) do
    parse(mint_messages, request_ref, %{http_response | body: [data | http_response.body]})
  end

  def parse(
        [{:done, request_ref}],
        request_ref,
        http_response = %HTTP.Response{}
      ) do
    {:ok, %{http_response | body: Enum.reverse(http_response.body), complete?: true}}
  end

  def parse([{_, mint_request_ref, _} | _], request_ref, _)
      when mint_request_ref != request_ref,
      do: {:error, :invalid_ref}

  def parse([{_, mint_request_ref} | _], request_ref, _)
      when mint_request_ref != request_ref,
      do: {:error, :invalid_ref}

  def parse([], _request_ref, http_response), do: {:ok, http_response}
end
