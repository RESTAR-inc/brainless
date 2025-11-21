defmodule Brainless.Rag.Prediction.Provider.Local do
  @moduledoc """
  Bumblebee impl
  """

  use Brainless.Rag.Prediction.Provider
  require Logger

  @spec serving(opts :: keyword()) :: Nx.Serving.t()
  def serving(opts) do
    model_repo = {:hf, Keyword.get(opts, :model)}
    {:ok, model_info} = Bumblebee.load_model(model_repo)
    {:ok, tokenizer} = Bumblebee.load_tokenizer(model_repo)
    {:ok, generation_config} = Bumblebee.load_generation_config(model_repo)

    Logger.info("Starting Bumblebee generator...")

    Bumblebee.Text.generation(model_info, tokenizer, generation_config,
      compile: [batch_size: 1, sequence_length: 1028],
      defn_options: [compiler: EXLA]
    )
  end

  @impl true
  def predict(input, _opts) do
    case Nx.Serving.batched_run(__MODULE__, input) do
      %{results: _results} ->
        # dbg(_results)
        {:ok, ""}

      reason ->
        {:error, reason}
    end
  end
end
