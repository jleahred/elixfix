defmodule Elixfix.Mixfile do
  use Mix.Project

  def project do
    [app: :elixfix,
     version: "0.0.1-dev",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     source_url: "https://github.com/jleahred/elixfix",
     homepage_url: "https://github.com/jleahred/elixfix",
     docs: [logo: "jleahred_r.png",
          extras: ["README.md"]],
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger],
     mod: {Elixfix, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:earmark, "~> 0.1", only: :dev},
     {:ex_doc, "~> 0.11", only: :dev},
     {:credo, "~> 0.3", only: [:dev, :test]},
     {:dialyxir, "~> 0.3", only: [:dev]}
    ]
  end
end
