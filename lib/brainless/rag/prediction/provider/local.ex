defmodule Brainless.Rag.Prediction.Provider.Local do
  @moduledoc """
  Local impl
  """

  use Brainless.Rag.Prediction.Provider
  require Logger

  @impl true
  def predict(_input, _opts) do
    {:error, "NOT IMPLEMENTED"}
  end
end
