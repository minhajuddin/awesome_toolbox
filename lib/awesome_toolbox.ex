defmodule AwesomeToolbox do
  alias AwesomeToolbox.Github
  require Logger

  def annotate_with_time(repo_name) do
    {us, {:ok, readme}} = :timer.tc(fn -> annotate_readme(repo_name) end)

    IO.puts("""
    # ------------------------------
    # Time taken: #{us / 1000} milliseconds
    # ------------------------------
    # README
    # ------------------------------

    #{readme}
    """)
  end

  # annotates a readme with star count
  def annotate_readme(repo_name) do
    # if we don't find a readme, just return the error
    with {:ok, readme} <- Github.readme(repo_name) do
      annotated_readme =
        readme
        |> IO.inspect(label: "README> ")
        # split the readme on newlines
        |> String.split("\n")
        # annotate each line
        |> Enum.map(&annotate_line/1)
        # join them back using newlines
        |> Enum.join("\n")

      {:ok, annotated_readme}
    end
  end

  @github_repo_rx ~r/https:\/\/github.com\/(?<repo_name>[0-9a-zA-Z._-]+\/[0-9a-zA-Z._-]+)/
  @star <<0x2B_50::utf8>>
  defp annotate_line(line) do
    # find the github repo link
    with %{"repo_name" => repo_name} <- Regex.named_captures(@github_repo_rx, line),
         # get the star count
         {:repo_info, {:ok, %{"stargazers_count" => stargazers_count}}} <-
           {:repo_info, Github.repo_info(repo_name)} do
      # append it to the link
      IO.write(".")

      Regex.replace(
        ~r/(\(?https:\/\/github.com\/#{repo_name}\)?)/,
        line,
        "\\1 (#{stargazers_count} #{@star})"
      )
    else
      # in case of an error log and return the unchanged line
      {:error, error} ->
        Logger.error("ANNOTATE_LINE_ERROR: #{inspect(error)}")
        line

      {:repo_info, err_resp} ->
        Logger.error("ANNOTATE_LINE_ERROR: #{inspect(err_resp)}")

      # if we don't find a github link, return the unchanged line
      _ ->
        line
    end
  end
end
