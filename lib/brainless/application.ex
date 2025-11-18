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

    base_children =
      case Brainless.Rag.Embedding.provider() do
        :local ->
          base_children ++
            [
              {Nx.Serving,
               name: Brainless.Rag.Embedding.Provider.Local,
               batch_timeout: 50,
               serving: Brainless.Rag.Embedding.Provider.Local.serving()}
            ]

        _ ->
          base_children
      end

    base_children =
      case Brainless.Rag.Generation.provider() do
        :local ->
          base_children ++
            [
              {Nx.Serving,
               name: Brainless.Rag.Generation.Provider.Local,
               batch_timeout: 50,
               serving: Brainless.Rag.Generation.Provider.Local.serving()}
            ]

        _ ->
          base_children
      end

    base_children ++ [BrainlessWeb.Endpoint]
  end
end
