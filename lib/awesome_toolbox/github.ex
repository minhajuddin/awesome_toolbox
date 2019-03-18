defmodule AwesomeToolbox.Github do
  def zen do
    # open a new http connection to api.github.com and get a handle to the connection struct
    {:ok, conn} = Mint.HTTP.connect(_scheme = :https, _host = "api.github.com", _port = 443)

    # make a GET request to the `/zen` path using the above connection without any special headers
    {:ok, conn, request_ref} =
      Mint.HTTP.request(conn, _method = "GET", _path = "/zen", _headers = [])

    # receive and parse the response
    receive do
      message ->
        # send received message to `Mint` to be parsed
        {:ok, conn, responses} = Mint.HTTP.stream(conn, message)

        for response <- responses do
          case response do
            {:status, ^request_ref, status_code} ->
              IO.puts("> Response status code #{status_code}")

            {:headers, ^request_ref, headers} ->
              IO.puts("> Response headers: #{inspect(headers)}")

            {:data, ^request_ref, data} ->
              IO.puts("> Response body")
              IO.puts(data)

            {:done, ^request_ref} ->
              IO.puts("> Response fully received")
          end
        end

        Mint.HTTP.close(conn)
    end
  end
end
