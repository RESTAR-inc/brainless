defmodule Brainless.Rag.Generation.Provider.Gemini do
  @moduledoc """
  Gemini generator
  """
  use Brainless.Rag.Generation.Provider

  @model_repo "google:gemini-2.5-flash"

  @impl true
  def predict(input) do
    case ReqLLM.generate_text(@model_repo, input) do
      {:ok, response} ->
        {:ok, Enum.map(response.message.content, & &1.text)}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
