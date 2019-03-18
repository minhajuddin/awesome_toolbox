defmodule AwesomeToolbox.MixProject do
  use Mix.Project

  def project do
    [
      app: :awesome_toolbox,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {AwesomeToolbox.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:mint, ">= 0.0.0"},
      {:castore, ">= 0.0.0"},
      {:jason, ">= 0.0.0"}
    ]
  end
end
