defmodule AwesomeToolbox.Github do
  def zen do
    {:ok, resp} = HTTP.get("https://api.github.com/zen")
    {:ok, resp.body}
  end

  def readme(repo_full_name) do
    # make the request
    {:ok, resp} = HTTP.get("https://api.github.com/zen")

    # decode json
    {:ok, json} = Jason.decode(resp.body)

    cond do
      resp.status > 400 -> {:error, json}
      resp.headers
    end
    # if the response has hit a rate limit return that



    {:ok, conn} = Mint.HTTP.connect(:https, "api.github.com", 443)

    {:ok, conn, request_ref} =
      Mint.HTTP.request(conn, "GET", "/repos/#{repo_full_name}/readme", [
        {"content-type", "application/json"}
      ])

    {:ok, status, conn, body} = recv_response(conn, request_ref)

    json = Jason.decode!(body)

    readme = Base.decode64!(json["content"], ignore: :whitespace)

    Mint.HTTP.close(conn)
    {:ok, readme}
  end

  @doc """
  Get the repo info for the given repo
  e.g
      iex> repo_info("minhajuddin/awesome_toolbox")
      %{"stargazers_count" => 0, ...}
  """
  def repo_info(repo_full_name) do
    # create an HTTP connection
    {:ok, conn} = Mint.HTTP.connect(:https, "api.github.com", 443)

    # make a GET request to get the repo info
    {:ok, conn, request_ref} =
      Mint.HTTP.request(conn, "GET", "/repos/#{repo_full_name}", [
        {"content-type", "application/json"}
      ])

    # read and parse the response
    {:ok, conn, body} = recv_response(conn, request_ref)

    # decode the JSON
    json = Jason.decode!(body)

    # close the HTTP connection
    Mint.HTTP.close(conn)
    {:ok, json}
  end

  defmodule HTTPResponse do
    defstruct status_code: nil, headers: nil, body: []
  end

  defp recv_response(conn, request_ref, http_response \\ %HTTPResponse{}) do
    # receive and parse the response

    {conn, http_response} =
      receive do
        message ->
          # send received message to `Mint` to be parsed
          {:ok, conn, mint_responses} = Mint.HTTP.stream(conn, message)

          http_response =
            Enum.reduce(mint_responses, {:incomplete, http_response}, fn mint_response, acc ->
              case mint_response do
                {:status, ^request_ref, status_code} ->
                  %{http_response | status_code: status_code}

                {:headers, ^request_ref, headers} ->
                  %{http_response | headers: headers}

                {:data, ^request_ref, data} ->
                  %{http_response | body: [data | http_response.body]}

                {:done, ^request_ref} ->
                  %{http_response | complete?: true}
              end
            end)

          {conn, http_response}
      end

    if http_response.complete? do
      {:ok, conn, %{http_response | body: Enum.reverse(http_response.body)}}
    else
      recv_response(conn, request_ref, http_response)
    end
  end
end
