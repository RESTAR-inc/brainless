defmodule Brainless.Rag.Embedding do
  @moduledoc """
  See https://developers.googleblog.com/en/gemini-embedding-available-gemini-api/
  """

  @model_bumblebee {:hf, "intfloat/e5-large-v2"}
  @model_gemini "models/text-embedding-004"

  def serving do
    {:ok, model_info} = Bumblebee.load_model(@model_bumblebee)
    {:ok, tokenizer} = Bumblebee.load_tokenizer(@model_bumblebee)

    Bumblebee.Text.text_embedding(model_info, tokenizer,
      embedding_processor: :l2_norm,
      defn_options: [compiler: EXLA]
    )
  end

  def predict(:bumblebee, text) when is_binary(text) do
    Nx.Serving.batched_run(__MODULE__, text)
  end

  def predict(:gemini, text) when is_binary(text) do
    case ExLLM.Providers.Gemini.Embeddings.embed_text(@model_gemini, text) do
      {:ok, %{values: vector}} ->
        {:ok, vector}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def predict_many(:bumblebee, _) do
    raise("Not implemented")
  end

  def predict_many(:gemini, texts) when is_list(texts) do
    case ExLLM.Providers.Gemini.Embeddings.embed_texts(@model_gemini, texts,
           cache: true,
           cache_ttl: :timer.minutes(10)
         ) do
      {:ok, values} ->
        {:ok, values |> Enum.map(fn %{values: embeddings} -> embeddings end)}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
