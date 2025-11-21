defmodule Brainless.Rag.Embedding do
  @moduledoc """
  Root embedding
  """
  alias Brainless.Rag.Embedding.Provider.Gemini
  alias Brainless.Rag.Embedding.Provider.Local

  @spec to_vector(input :: String.t()) :: {:error, term()} | {:ok, [float()]}
  def to_vector(input) do
    case get_provider() do
      :gemini ->
        Gemini.to_vector(input,
          model: get_model(),
          dimensions: get_dimensions()
        )

      :local ->
        Local.to_vector(input)
    end
  end

  @spec to_vector_list(inputs :: [String.t()]) :: {:error, map()} | {:ok, [[float()]]}
  def to_vector_list(inputs) do
    case get_provider() do
      :gemini ->
        Gemini.to_vector_list(inputs,
          model: get_model(),
          dimensions: get_dimensions()
        )

      :local ->
        Local.to_vector_list(inputs)
    end
  end

  def get_provider do
    Keyword.fetch!(Application.fetch_env!(:brainless, __MODULE__), :provider)
  end

  def get_dimensions do
    Keyword.fetch!(Application.fetch_env!(:brainless, __MODULE__), :dimensions)
  end

  def get_model do
    Keyword.fetch!(Application.fetch_env!(:brainless, __MODULE__), :model)
  end
end
