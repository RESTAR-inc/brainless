defmodule Brainless.Rag.Embedding.Provider do
  @moduledoc """
  Embedding behavior
  """
  alias Brainless.Rag.Embedding.IndexData

  @callback to_vector(String.t(), keyword()) ::
              {:error, term()} | {:ok, [float()]}
  @callback to_index_list([IndexData.t()], keyword()) ::
              {:error, map()} | {:ok, [{IndexData.t(), [float()]}]}

  defmacro __using__(_opts) do
    quote do
      @behaviour Brainless.Rag.Embedding.Provider
    end
  end
end
