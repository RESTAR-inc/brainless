defmodule Brainless.Rag.Embedding.Provider.Local do
  @moduledoc """
  List of compatible models with 768 dimensions
    - sentence-transformers/gtr-t5-base (~220 MB, english only)
    - sentence-transformers/LaBSE (~1.9 GB, multilang)
    - sentence-transformers/distiluse-base-multilingual-cased-v2 (~540 MB, multilang)
    - sentence-transformers/paraphrase-multilingual-mpnet-base-v2 (~1.1 GB, multilang)

  """
  use Brainless.Rag.Embedding.Provider
  require Logger

  @spec serving(opts :: keyword()) :: Nx.Serving.t()
  def serving(opts) do
    model_repo = {:hf, Keyword.get(opts, :model)}

    {:ok, model_info} = Bumblebee.load_model(model_repo)
    {:ok, tokenizer} = Bumblebee.load_tokenizer(model_repo)

    Logger.info("Starting Bumblebee embedding...")

    Bumblebee.Text.text_embedding(model_info, tokenizer,
      embedding_processor: :l2_norm,
      defn_options: [compiler: EXLA],
      output_attribute: :hidden_state,
      output_pool: :mean_pooling
    )
  end

  @impl true
  def to_vector(input, _opts \\ []) do
    case Nx.Serving.batched_run(__MODULE__, input) do
      %{embedding: embedding} ->
        {:ok, embedding |> Nx.to_list()}

      _ ->
        {:error, "error"}
    end
  end

  @impl true
  def to_vector_list(inputs, _opts \\ []) do
    case Nx.Serving.batched_run(__MODULE__, inputs) do
      values when is_list(values) ->
        embeddings = Enum.map(values, fn %{embedding: embedding} -> Nx.to_list(embedding) end)
        {:ok, embeddings}

      _ ->
        {:error, "error"}
    end
  end
end
