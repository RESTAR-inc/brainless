defmodule Brainless.Rag.Generation.Provider do
  @moduledoc """
  Generation provider behaviour
  """
  @callback predict(input :: String.t()) :: {:error, term()} | {:ok, [String.t()]}

  defmacro __using__(_opts) do
    quote do
      @behaviour Brainless.Rag.Generation.Provider
    end
  end
end
