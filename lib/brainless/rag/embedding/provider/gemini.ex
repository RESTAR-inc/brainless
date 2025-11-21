defmodule Brainless.Rag.Embedding.Provider.Gemini do
  @moduledoc """
    See https://developers.googleblog.com/en/gemini-embedding-available-gemini-api/
  """
  use Brainless.Rag.Embedding.Provider

  @impl true
  def to_vector(input, opts) do
    dimensions = Keyword.get(opts, :dimensions)
    model = Keyword.get(opts, :model)

    ReqLLM.embed(model, input, dimensions: dimensions)
  end

  @impl true
  def to_vector_list(inputs, opts) do
    dimensions = Keyword.get(opts, :dimensions)
    model = Keyword.get(opts, :model)

    ReqLLM.embed(model, inputs, dimensions: dimensions)
  end
end
