defmodule Taco.Mixfile do
  use Mix.Project

  def project do
    [
      app: :taco,
      version: "0.1.0",
      name: "Taco",
      description: "Composition and error handling of sequential computations",
      source_url: "https://github.com/arkgil/taco",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      docs: docs(),
      package: package()
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

  defp package do
    [
      licenses: ["MIT"],
      maintainers: ["Arkadiusz Gil"],
      links: %{"GitHub" => "https://github.com/arkgil/taco"}
    ]
  end
end
