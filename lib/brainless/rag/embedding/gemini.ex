defmodule Brainless.Rag.Embedding.Gemini do
  @moduledoc """
    See https://developers.googleblog.com/en/gemini-embedding-available-gemini-api/
  """
  use Brainless.Rag.Embedding.Provider

  @model_gemini "google:gemini-embedding-001"

  @impl true
  def to_vector(input) do
    ReqLLM.embed(@model_gemini, input, dimensions: 768)
  end

  @impl true
  def to_vector_list(inputs) do
    ReqLLM.embed(@model_gemini, inputs, dimensions: 768)
  end
end
