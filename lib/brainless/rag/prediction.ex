defmodule Brainless.Rag.Prediction do
  @moduledoc """
  Text generator
  """
  alias ReqLLM.Message.ContentPart

  @spec predict(input :: String.t(), opts :: keyword()) :: {:error, term()} | {:ok, String.t()}
  def predict(input, opts \\ []) do
    model = get_model()
    model_input = prepare_input(input, opts)

    case ReqLLM.generate_text(model, model_input) do
      {:ok, response} ->
        {:ok, format_content(response.message.content)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_model do
    Keyword.fetch!(Application.fetch_env!(:brainless, __MODULE__), :model)
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

  defp format_content(_), do: raise("Invalid content")

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
