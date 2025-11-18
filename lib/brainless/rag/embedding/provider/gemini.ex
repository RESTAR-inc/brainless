defmodule Brainless.Rag.Embedding.Provider.Gemini do
  @moduledoc """
    See https://developers.googleblog.com/en/gemini-embedding-available-gemini-api/
  """
  use Brainless.Rag.Embedding.Provider

  @model_gemini "google:gemini-embedding-001"

  @impl true
  def to_vector(input, opts) do
    dimensions = Keyword.get(opts, :dimensions)
    ReqLLM.embed(@model_gemini, input, dimensions: dimensions)
  end

  @impl true
  def to_vector_list(inputs, opts) do
    dimensions = Keyword.get(opts, :dimensions)
    ReqLLM.embed(@model_gemini, inputs, dimensions: dimensions)
  end
end
