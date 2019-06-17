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
    else
      err -> {:error, err}
    end
  end

  def repo_info(repo_name) do
    with {:ok, %HTTP.Response{status_code: 200} = resp} <-
           HTTP.get("https://api.github.com/repos/#{repo_name}"),
         {:ok, repo_info} <- Jason.decode(resp.body) do
      {:ok, repo_info}
    else
      err -> {:error, err}
    end
  end
end
