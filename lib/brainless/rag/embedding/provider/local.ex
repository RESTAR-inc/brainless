defmodule Brainless.Rag.Embedding.Provider.Local do
  @moduledoc """
  TODO
  """

  use Brainless.Rag.Embedding.Provider
  require Logger

  @impl true
  def to_vector(input, _opts \\ []) do
    case Req.post(get_url(:one), json: %{content: input, meta: %{}}) do
      {:ok, %Req.Response{body: body}} ->
        {:ok, map_response_item(body)}

      {:error, _reason} ->
        {:error, "Unable to create a vector"}
    end
  end

  @impl true
  def to_vector_list(inputs, _opts \\ []) do
    # Req.get!("https://api.github.com/repos/wojtekmach/req").body["description"]

    documents = Enum.map(inputs, &%{content: &1, meta: %{}})

    case Req.post(get_url(:many), json: documents) do
      {:ok, %Req.Response{body: body}} ->
        {:ok, Enum.map(body, &map_response_item/1)}

      {:error, _reason} ->
        {:error, "Unable to create a vector list"}
    end
  end

  defp map_response_item(%{"content" => content}) when is_list(content), do: content

  defp get_url(:many), do: "#{get_service_url()}/api/embeddings/many"
  defp get_url(:one), do: "#{get_service_url()}/api/embeddings/one"

  defp get_service_url do
    Keyword.fetch!(Application.fetch_env!(:brainless, Brainless.Rag.Embedding), :service_url)
  end
end
