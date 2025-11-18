defmodule Brainless.Rag.Generation do
  @moduledoc """
  Root generator
  """
  use Brainless.Rag.Generation.Provider

  alias Brainless.Rag.Generation.Provider.Gemini
  alias Brainless.Rag.Generation.Provider.Local

  @impl true
  def predict(input) do
    case provider() do
      :gemini -> Gemini.predict(input)
      :local -> Local.predict(input)
    end
  end

  def provider do
    Keyword.fetch!(Application.fetch_env!(:brainless, __MODULE__), :provider)
  end
end
