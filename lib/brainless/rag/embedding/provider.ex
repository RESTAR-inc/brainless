defmodule Brainless.Rag.Embedding.Provider do
  @moduledoc """
  Embedding behavior
  """
  alias Brainless.Rag.Embedding.EmbedData
  alias Brainless.Rag.Embedding.EmbedDocument

  @callback str_to_vector(input :: String.t(), opts :: keyword()) ::
              {:error, term()} | {:ok, [float()]}
  @callback docs_to_index_list(documents :: [EmbedDocument.t()], opts :: keyword()) ::
              {:error, map()} | {:ok, [EmbedData.t()]}

  defmacro __using__(_opts) do
    quote do
      @behaviour Brainless.Rag.Embedding.Provider
    end
  end
end
