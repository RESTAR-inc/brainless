defmodule BrainlessWeb.MediaLive.Index do
  use BrainlessWeb, :live_view

  import BrainlessWeb.Media.Components

  alias Brainless.Rag
  alias Brainless.Rag.Response

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Media")
     |> assign(:ai_response, nil)
     |> assign(:query, nil)
     |> assign(:results, [])}
  end

  @impl true
  def handle_event("search", %{"query" => query, "use_ai_summary" => use_ai_summary}, socket) do
    use_ai_summary =
      case use_ai_summary do
        "true" -> true
        "false" -> false
      end

    query = String.trim(query)
    search(socket, query, use_ai_summary)
  end

  defp search(socket, "", _) do
    {:noreply, socket |> assign(:results, [])}
  end

  defp search(socket, query, use_ai_summary) do
    case Rag.search(:media, query, use_ai_summary: use_ai_summary) do
      {:ok, %Response{results: results, ai_response: ai_response}} ->
        {:noreply,
         socket
         |> assign(:results, results)
         |> assign(:query, query)
         |> assign(:ai_response, to_md(ai_response))}

      {:error, _} ->
        {:noreply,
         socket
         |> assign(:results, [])
         |> assign(:query, nil)
         |> assign(:ai_response, nil)}
    end
  end

  defp to_md(nil), do: nil

  defp to_md(input) when is_binary(input) do
    case MDEx.to_html(input) do
      {:ok, html} -> html
      {:error, _} -> nil
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
            name="use_ai_summary"
            label="Use AI Summary"
          />
        </div>
      </form>

      <div :if={@ai_response != nil} class="p-2 w-full markdown">
        {raw(@ai_response)}
      </div>

      <div :if={@results != []} class="flex flex-col divide-y">
        <div class="p-4">Found {length(@results)}</div>
        <%= for result <- @results do %>
          <.movie :if={result.type == "movie"} movie={result.data} score={result.score} class="p-4" />
          <.book :if={result.type == "book"} book={result.data} score={result.score} class="p-4" />
        <% end %>
      </div>
      <div :if={@results == [] && @query != nil} class="flex items-center justify-center">
        Nothing found
      </div>
    </Layouts.app>
    """
  end
end
