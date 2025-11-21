defmodule Brainless.Rag.Prediction.Provider do
  @moduledoc """
  Generation provider behaviour
  """
  @callback predict(input :: String.t(), opts :: keyword()) ::
              {:error, term()} | {:ok, String.t()}

  defmacro __using__(_opts) do
    quote do
      @behaviour Brainless.Rag.Prediction.Provider
    end
  end
end
