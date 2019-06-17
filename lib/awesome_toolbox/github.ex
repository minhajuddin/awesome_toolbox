defmodule AwesomeToolbox.Github do
  require Logger

  def zen do
    {:ok, resp} = HTTP.get("https://api.github.com/zen")
    {:ok, resp.body}
  end

  def readme(repo_name) do
    # make the request
    with {:ok, %HTTP.Response{status_code: 200} = resp} <-
           HTTP.get("https://api.github.com/repos/#{repo_name}/readme"),
         # decode json
         {:ok, json} <- Jason.decode(resp.body),
         {:ok, readme} <- Base.decode64(json["content"], ignore: :whitespace) do
      {:ok, readme}
    end
  end

  @doc """
  Get the repo info for the given repo
  e.g
      iex> repo_info("minhajuddin/awesome_toolbox")
      {:ok, %{"stargazers_count" => 0, ...}}
  """
  def repo_info(repo_name) do
    with {:ok, %HTTP.Response{status_code: 200} = resp} <-
           HTTP.get("https://api.github.com/repos/#{repo_name}"),
         {:ok, repo_info} <- Jason.decode(resp.body) do
      {:ok, repo_info}
    else
      err ->
        Logger.error("REPO_INFO_ERROR: #{inspect(err)}")
        {:error, err}
    end
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
