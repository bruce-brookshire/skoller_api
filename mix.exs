defmodule Skoller.Mixfile do
  use Mix.Project

  def project do
    [
      app: :skoller,
      version: "3.0.0",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
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
      extra_applications: [:logger, :runtime_tools, :elixir_xml_to_map, :timex, :ex_aws, :ex_aws_s3],
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:arc, "~> 0.11.0"},
      {:basic_auth, "~> 2.2"},
      {:bcrypt_elixir, "~> 3.0"},
      {:comeonin, "~> 5.3"},
      {:cors_plug, "~> 3.0.3"},
      {:credo, "~> 1.6.4", only: [:dev, :test], runtime: false},
      {:csv, "~> 2.4.1"},
      {:ecto, "~> 3.8.4"},
      {:ecto_sql, "~> 3.8.3"},
      {:ecto_enum, "~> 1.4"},
      {:elixir_xml_to_map, "~> 3.0.0"},
      {:ex_aws, "~> 2.3.3"},
      {:ex_aws_s3, "~> 2.3.3"},
      {:ex_aws_ses, "~> 2.4.1"},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:ex_mvc, "~> 0.3.0", github: "flyrboy96/ex_mvc"},
      {:ex_twilio, "~> 0.9.1"},
      {:gettext, "~> 0.11"},
      {:faker, "~> 0.17.0"},
      {:guardian, "~> 2.1"},
      {:kadabra, "~> 0.6.0"},
      {:mail, "~> 0.2.0", git: "https://github.com/DockYard/elixir-mail.git", override: true},
      {:oban, "~> 2.12"},
      {:phoenix, "~> 1.6.11"},
      {:phoenix_html, "~> 3.2"},
      {:phoenix_pubsub, "~> 2.0"},
      {:phoenix_ecto, "~> 4.0"},
      {:pigeon, "~> 1.6.1"},
      {:plug_cowboy, "~> 2.0"},
      {:plug, "~> 1.7"},
      {:poison, "~> 3.1"},
      {:postgrex, ">= 0.0.0"},
      {:sweet_xml, "~> 0.6"},
      {:timex, "~> 3.7.8"},
      {:tzdata, "~> 1.1.1"},
      {:stripity_stripe, "~> 2.0"},

      # Test
      {:ex_machina, "~> 2.7", only: :test},
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
      "ecto.setup": ["ecto.create", "ecto.migrate_s", "run priv/repo/seeds.exs", "seed.dev"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.drop --quiet", "ecto.create --quiet", "ecto.migrate_s", "test"],
      "ecto.migrate_s": ["ecto.migrate.startup", "ecto.migrate"]
    ]
  end
end
