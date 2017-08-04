defmodule Taco.Mixfile do
  use Mix.Project

  def project do
    [
      app: :taco,
      version: "0.1.0",
      name: "Taco",
      description: "Composition and error handling of sequential computations",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:credo, "~> 0.8", only: :dev, runtime: false},
      {:dialyxir, "~> 0.5", only: :dev, runtime: false},
    ]
  end

  defp docs do
    [
      main: "Taco",
      extras: ["README.md": [title: "Taco"]]
    ]
  end
end
