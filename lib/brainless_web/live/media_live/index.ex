defmodule BrainlessWeb.MediaLive.Index do
  use BrainlessWeb, :live_view

  import BrainlessWeb.Media.Components

  alias Brainless.Rag
  alias Brainless.Rag.Document.MediaDocument

  defp to_md(input) do
    case MDEx.to_html(input) do
      {:ok, html} -> html
      {:error, _} -> nil
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Media")
     |> assign(:ai_response, nil)
     |> assign(:query, nil)
     |> assign(:media_list, [])}
  end

  @impl true
  def handle_event("search", %{"query" => query, "use_ai" => use_ai}, socket) do
    use_ai =
      case use_ai do
        "true" -> true
        "false" -> false
      end

    query = String.trim(query)
    search(socket, query, use_ai)
  end

  defp search(socket, "", _) do
    {:noreply, socket |> assign(:media_list, [])}
  end

  defp search(socket, query, use_ai) do
    case Rag.search(MediaDocument.index_name(), query, use_ai: use_ai) do
      {:ok, media_list, ai_response} ->
        {:noreply,
         socket
         |> assign(:media_list, media_list)
         |> assign(:query, query)
         |> assign(:ai_response, to_md(ai_response))}

      {:error, _} ->
        {:noreply,
         socket
         |> assign(:media_list, [])
         |> assign(:query, nil)
         |> assign(:ai_response, nil)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Media
        <:actions>
          <.button variant="primary" navigate={~p"/movies/new"}>
            <.icon name="hero-plus" /> New Movie
          </.button>
        </:actions>
      </.header>

      <form phx-submit="search" class="flex flex-col items-end">
        <div class="w-full">
          <.input type="text" name="query" value="" label="Query" />
        </div>
        <div class="flex gap-4 items-start">
          <.button phx-disable-with="..." variant="primary">Search</.button>
          <.input
            type="checkbox"
            name="use_ai"
            label="Use AI"
          />
        </div>
      </form>

      <div :if={@ai_response != nil} class="p-2 w-full markdown">
        {raw(@ai_response)}
      </div>

      <div :if={@media_list != []} class="flex flex-col divide-y">
        <div class="p-4">Found {length(@media_list)}</div>
        <%= for {media, media_type, score} <- @media_list do %>
          <.movie :if={media_type == "movie"} movie={media} score={score} class="p-4" />
          <.book :if={media_type == "book"} book={media} score={score} class="p-4" />
        <% end %>
      </div>
      <div :if={@media_list == [] && @query != nil} class="flex items-center justify-center">
        Nothing found
      </div>
    </Layouts.app>
    """
  end
end
