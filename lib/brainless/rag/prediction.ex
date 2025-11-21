defmodule Brainless.Rag.Prediction do
  @moduledoc """
  Root generator
  """

  alias Brainless.Rag.Prediction.Provider.Gemini
  alias Brainless.Rag.Prediction.Provider.Local

  @spec predict(input :: String.t(), opts :: keyword()) :: {:error, term()} | {:ok, String.t()}
  def predict(input, opts \\ []) do
    opts = Keyword.put_new(opts, :model, get_model())

    case get_provider() do
      :gemini -> Gemini.predict(input, opts)
      :local -> Local.predict(input, opts)
    end
  end

  def get_provider do
    Keyword.fetch!(Application.fetch_env!(:brainless, __MODULE__), :provider)
  end

  def get_model do
    Keyword.fetch!(Application.fetch_env!(:brainless, __MODULE__), :model)
  end
end
