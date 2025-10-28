defmodule Brainless.Rag.Embedding do
  @moduledoc """
  See https://developers.googleblog.com/en/gemini-embedding-available-gemini-api/
  """

  @model_repo {:hf, "intfloat/e5-large-v2"}

  def serving do
    {:ok, model_info} = Bumblebee.load_model(@model_repo)
    {:ok, tokenizer} = Bumblebee.load_tokenizer(@model_repo)

    Bumblebee.Text.text_embedding(model_info, tokenizer,
      embedding_processor: :l2_norm,
      defn_options: [compiler: EXLA]
    )
  end

  def predict(text) do
    Nx.Serving.batched_run(__MODULE__, text)
  end
end
