defmodule Brainless.Rag.Embedding do
  @moduledoc """
  Root embedding
  """
  alias Brainless.Rag.Embedding.Provider.Local
  alias Brainless.Rag.Embedding.Provider.Gemini

  @spec to_vector(input :: String.t()) :: {:error, term()} | {:ok, [float()]}
  def to_vector(input) do
    case provider() do
      :gemini -> Gemini.to_vector(input, dimensions: dimensions())
      :local -> Local.to_vector(input)
    end
  end

  @callback to_vector_list(inputs :: [String.t()]) :: {:error, map()} | {:ok, [[float()]]}
  def to_vector_list(inputs) do
    case provider() do
      :gemini -> Gemini.to_vector_list(inputs, dimensions: dimensions())
      :local -> Local.to_vector_list(inputs)
    end
  end

  def provider do
    Keyword.fetch!(Application.fetch_env!(:brainless, __MODULE__), :provider)
  end

  def dimensions do
    Keyword.fetch!(Application.fetch_env!(:brainless, __MODULE__), :dimensions)
  end
end
