defmodule Skoller.Mixfile do
  use Mix.Project

  def project do
    [
      app: :skoller,
      version: "2.2.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix, :gettext] ++ Mix.compilers,
      start_permanent: Mix.env == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Skoller.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:phoenix, "~> 1.3.0"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 3.2"},
      {:postgrex, ">= 0.0.0"},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 1.0"},
      {:guardian, "~> 1.0-beta"},
      {:arc, "~> 0.10.0"},
      {:arc_ecto, "~> 0.10.0"},
      {:ex_aws, "~> 2.0"},
      {:ex_aws_s3, "~> 2.0"},
      {:hackney, "~> 1.13"},
      {:poison, "~> 3.1"},
      {:sweet_xml, "~> 0.6"},
      {:comeonin, "~> 4.0"},
      {:bcrypt_elixir, "~> 1.0"},
      {:cors_plug, "~> 1.2"},
      {:pigeon, "~> 1.2.2"},
      {:kadabra, "~> 0.4.2"},
      {:ex_twilio, "~> 0.5.0"},
      {:csv, "~> 2.0.0"},
      {:bamboo, "~> 0.8"},
      {:bamboo_smtp, "~> 1.4.0"},
      {:timex, "~> 3.1"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs", "seed.dev"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"],
      "ecto.migrate_s": ["ecto.migrate.startup", "ecto.migrate"]
    ]
  end
end
