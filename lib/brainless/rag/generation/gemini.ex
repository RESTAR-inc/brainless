defmodule Brainless.Rag.Generation.Gemini do
  use Brainless.Rag.Generation.Provider

  @model_repo "google:gemini-2.5-flash"

  @impl true
  def generate(input) do
    case ReqLLM.generate_text(@model_repo, input) do
      {:ok, response} ->
        {:ok, Enum.map(response.message.content, fn %{text: text} -> text end)}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
