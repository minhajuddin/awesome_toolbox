defmodule HTTP do
  require Logger
  def get(uri, headers \\ []), do: request("GET", uri, headers)

  def request(method, uri, headers \\ [], body \\ [])

  def request(method, uri, headers, body)
      when is_list(headers) and method in ~w[GET POST PUT PATCH DELETE OPTIONS HEAD] and
             is_binary(uri) do
    request(method, URI.parse(uri), headers, body)
  end

  def request(method, uri = %URI{}, headers, body)
      when is_list(headers) and method in ~w[GET POST PUT PATCH DELETE OPTIONS HEAD] do
    # TODO: spawn a new process per request so that the messages don't get intermingled

    # get an existing connection if it is already available
    conn = get_connection(uri)

    Logger.info("#{method} #{uri}")

    {:ok, conn, request_ref} = Mint.HTTP.request(conn, method, path(uri), headers, body)

    {:ok, http_response = %HTTP.Response{}, conn} = recv_response(conn, request_ref)

    # put this connection in the process dictionary to be reused later
    put_connection(uri, conn)

    {:ok, http_response}
  end

  # Put our connection in the process dictionary keyed on the hostname so that
  # we don't reuse connections for different hosts.
  defp put_connection(uri, conn) do
    Process.put({:conn, uri.host}, conn)
  end

  # Get a connection if it was previously created, else create a new connection
  defp get_connection(uri) do
    conn = Process.get({:conn, uri.host})

    if conn do
      conn
    else
      Logger.info("creating HTTP connection to Github")
      {:ok, conn} = Mint.HTTP.connect(scheme_atom(uri.scheme), uri.host, uri.port)
      conn
    end
  end

  defp recv_response(conn, request_ref, http_response \\ %HTTP.Response{}) do
    receive do
      message ->
        # send received message to `Mint` to be parsed
        # TODO: handle :error
        {:ok, conn, mint_messages} = Mint.HTTP.stream(conn, message)

        case HTTP.Response.parse(mint_messages, request_ref, http_response) do
          {:ok, http_response = %HTTP.Response{complete?: true}} ->
            {:ok, http_response, conn}

          {:ok, http_response} ->
            recv_response(conn, request_ref, http_response)

          error ->
            error
        end
    end
  end

  # copied over from Mint
  defp path(uri) do
    IO.iodata_to_binary([
      if(uri.path, do: uri.path, else: ["/"]),
      if(uri.query, do: ["?" | uri.query], else: []),
      if(uri.fragment, do: ["#" | uri.fragment], else: [])
    ])
  end

  defp scheme_atom("https"), do: :https
  defp scheme_atom("http"), do: :http
  defp scheme_atom(_), do: throw(:invalid_scheme)
end
