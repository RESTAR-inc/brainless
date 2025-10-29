defmodule Brainless.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Brainless.Supervisor]
    Supervisor.start_link(children(), opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BrainlessWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp children do
    base_children = [
      BrainlessWeb.Telemetry,
      Brainless.Repo,
      {DNSCluster, query: Application.get_env(:brainless, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Brainless.PubSub}
    ]

    case Application.fetch_env!(:brainless, :ai_provider) do
      "bumblebee" ->
        base_children ++
          [
            {Nx.Serving,
             name: Brainless.Rag.Embedding,
             batch_timeout: 50,
             serving: Brainless.Rag.Embedding.serving()},
            {Nx.Serving,
             name: Brainless.Rag.Generation,
             batch_timeout: 50,
             serving: Brainless.Rag.Generation.serving()},
            # Start to serve requests, typically the last entry
            BrainlessWeb.Endpoint
          ]

      _ ->
        base_children ++
          [
            # Start to serve requests, typically the last entry
            BrainlessWeb.Endpoint
          ]
    end
  end
end
