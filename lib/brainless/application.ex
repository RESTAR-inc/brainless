defmodule Brainless.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      BrainlessWeb.Telemetry,
      Brainless.Repo,
      {DNSCluster, query: Application.get_env(:brainless, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Brainless.PubSub},
      # Start a worker by calling: Brainless.Worker.start_link(arg)
      # {Brainless.Worker, arg},
      # Start to serve requests, typically the last entry
      BrainlessWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Brainless.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BrainlessWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
