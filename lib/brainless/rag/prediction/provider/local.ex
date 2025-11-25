defmodule Brainless.Rag.Prediction.Provider.Local do
  @moduledoc """
  Bumblebee impl
  """

  use Brainless.Rag.Prediction.Provider
  require Logger

  @impl true
  def predict(input, _opts) do
    {:error, "NOT IMPLEMENTED"}
  end
end
