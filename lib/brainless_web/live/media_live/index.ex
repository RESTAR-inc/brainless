defmodule BrainlessWeb.MediaLive.Index do
  use BrainlessWeb, :live_view

  import BrainlessWeb.Media.Components

  alias Brainless.Rag
  alias Brainless.Rag.Document.MediaDocument

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Media")
     |> assign(:ai_response, nil)
     |> assign(:media_list, [])}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    query = String.trim(query)
    search(socket, query)
  end

  defp search(socket, "") do
    {:noreply, socket |> assign(:media_list, [])}
  end

  defp search(socket, query) do
    case Rag.search(MediaDocument.index_name(), query) do
      {:ok, media_list, ai_response} ->
        {:noreply,
         socket
         |> assign(:media_list, media_list)
         |> assign(:ai_response, ai_response)}

      {:error, _} ->
        {:noreply,
         socket
         |> assign(:media_list, [])
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

      <form phx-submit="search">
        <.input type="text" name="query" value="" />
        <.button phx-disable-with="..." variant="primary">Search</.button>
      </form>

      <div :if={@ai_response != nil} class="whitespace-pre-wrap p-2 w-full">
        {@ai_response}
      </div>

      <div class="flex flex-col list-none divide-y">
        <li :for={{media, media_type, score} <- @media_list} class="p-4">
          <.movie :if={media_type == "movie"} movie={media} score={score} />
          <.book :if={media_type == "book"} book={media} score={score} />
        </li>
      </div>
    </Layouts.app>
    """
  end
end
