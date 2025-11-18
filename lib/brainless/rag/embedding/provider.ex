defmodule Brainless.Rag.Embedding.Provider do
  @moduledoc """
  Embedding behavior
  """
  @callback to_vector(input :: String.t(), opts :: keyword()) ::
              {:error, term()} | {:ok, [float()]}
  @callback to_vector_list(inputs :: [String.t()], opts :: keyword()) ::
              {:error, map()} | {:ok, [[float()]]}

  defmacro __using__(_opts) do
    quote do
      @behaviour Brainless.Rag.Embedding.Provider
    end
  end
end
