defmodule BubbleTest.MixProject do
  use Mix.Project

  def project do
    [
      app: :bubble_test,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cowboy, "~> 2.6"},
      {:plug_cowboy, "~> 2.0"},
      {:plug, "~> 1.7"},
      {:httpoison, "~> 1.5", only: :test}
    ]
  end
end
