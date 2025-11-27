defmodule BrainlessWeb.MediaLive.Index do
  use BrainlessWeb, :live_view

  import BrainlessWeb.Media.MovieComponent

  alias Brainless.Rag
  alias Brainless.Rag.Document.MediaDocument

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Media")
     |> assign(:ai_response, "")
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
      {:ok, media, ai_response} ->
        {:noreply,
         socket
         |> assign(:media_list, media)
         |> assign(:ai_response, ai_response)}

      {:error, _} ->
        {:noreply,
         socket
         |> assign(:media_list, [])
         |> assign(:ai_response, "")}
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

      <div :if={@ai_response != ""} class="whitespace-pre-wrap p-2 w-full">
        {@ai_response}
      </div>

      <ul class="flex flex-col gap-4">
        <li :for={{media_type, media} <- @media_list}>
          <.movie :if={media_type == "movie"} movie={media} />
        </li>
      </ul>
    </Layouts.app>
    """
  end
end
