defmodule Brainless.Rag.Embedding do
  @model_repo {:hf, "intfloat/e5-large-v2"}
  # @model_repo {:hf, "google/gemma-3-27b-it"}

  def serving do
    {:ok, model_info} = Bumblebee.load_model(@model_repo)
    {:ok, tokenizer} = Bumblebee.load_tokenizer(@model_repo)

    Bumblebee.Text.text_embedding(model_info, tokenizer,
      embedding_processor: :l2_norm,
      defn_options: [compiler: EXLA]
    )
  end

  def predict(text) do
    # %{embedding: vector} =
    Nx.Serving.batched_run(__MODULE__, text)
  end
end
