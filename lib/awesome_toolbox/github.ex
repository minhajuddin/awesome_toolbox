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

  def readme(repo_full_name) do
    {:ok, conn} = Mint.HTTP.connect(:https, "api.github.com", 443)

    {:ok, conn, request_ref} =
      Mint.HTTP.request(conn, "GET", "/repos/#{repo_full_name}/readme", [
        {"content-type", "application/json"}
      ])

    # we now rely on the recv_response function to receive as many messages as
    # needed and process them till we have a full response body
    {:ok, conn, body} = recv_response(conn, request_ref)

    json = Jason.decode!(body)

    readme = Base.decode64!(json["content"], ignore: :whitespace)

    Mint.HTTP.close(conn)
    readme
  end

  # receive and parse the response till we get a :done mint response
  defp recv_response(conn, request_ref, body \\ []) do
    {conn, body, status} =
      receive do
        message ->
          # send received message to `Mint` to be parsed
          {:ok, conn, mint_responses} = Mint.HTTP.stream(conn, message)

          # reduce all the mint responses returning a partial body and status
          {body, status} =
            Enum.reduce(mint_responses, {body, :incomplete}, fn mint_response, {body, _status} ->
              case mint_response do
                # the :status mint-response doesn't add anything to the body and receiving this
                # doesn't signify the end of the response, let's ignore this for now.
                {:status, ^request_ref, _status_code} ->
                  {body, :incomplete}

                # the :headers mint-response doesn't add anything to the body and receiving this
                # doesn't signify the end of the response, let's ignore this for now.
                {:headers, ^request_ref, _headers} ->
                  {body, :incomplete}

                # the :data mint-response returns a partial body, let us append this
                # to the end of our accumulator, this still doesn't signify the end
                # of our response, so let's continue
                {:data, ^request_ref, data} ->
                  {body ++ [data], :incomplete}

                # the :done mint-response signifies the end of the response
                {:done, ^request_ref} ->
                  {body, :complete}
              end
            end)

          {conn, body, status}
      end

    # if the status is complete we can return the body which was accumulated till now
    if status == :complete do
      {:ok, conn, body}
      # else we make a tail recursive call to get more messages
    else
      recv_response(conn, request_ref, body)
    end
  end
end
