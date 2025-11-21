defmodule Brainless.Rag.Prediction.Provider.Gemini do
  @moduledoc """
  Gemini impl
  """
  use Brainless.Rag.Prediction.Provider

  alias ReqLLM.Message.ContentPart

  @impl true
  def predict(input, opts) do
    model = Keyword.get(opts, :model)
    model_input = prepare_input(input, opts)

    case ReqLLM.generate_text(model, model_input) do
      {:ok, response} ->
        content = format_content(response.message.content)
        {:ok, content}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp format_content(content) when is_list(content) do
    content
    |> Enum.map(fn
      %ContentPart{type: :text, text: text} ->
        text

      _ ->
        nil
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n")
  end

  defp format_content(_), do: ""

  defp prepare_input(input, opts) do
    case Keyword.get(opts, :system_prompt) do
      nil ->
        input

      system_prompt ->
        ReqLLM.Context.new([
          ReqLLM.Context.system(system_prompt),
          ReqLLM.Context.user(input)
        ])
    end
  end
end
