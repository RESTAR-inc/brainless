defmodule BrainlessWeb.BookLive.Index do
  use BrainlessWeb, :live_view

  import Ecto.Query
  import Pgvector.Ecto.Query

  alias Brainless.Repo
  alias Brainless.Shop
  alias Brainless.Shop.Book

  defmodule BrainlessWeb.BookLive.Index.SearchForm do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :query, :string
    end

    def changeset(search_form, attrs) do
      search_form
      |> cast(attrs, [:query])
      |> validate_required([:query])
    end
  end

  alias BrainlessWeb.BookLive.Index.SearchForm

  @impl true
  def mount(_params, _session, socket) do
    books = Shop.list_books()
    search_form = SearchForm.changeset(%SearchForm{}, %{}) |> to_form()

    {:ok,
     socket
     |> assign(:page_title, "Listing Books")
     |> assign(:search_form, search_form)
     |> stream(:books, books)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    book = Shop.get_book!(id)
    {:ok, _} = Shop.delete_book(book)

    {:noreply, stream_delete(socket, :books, book)}
  end

  @impl true
  def handle_event("search", %{"search_form" => %{"query" => query}}, socket) do
    query = String.trim(query)

    books =
      if String.length(query) == 0 do
        Shop.list_books()
      else
        {:ok, %{values: vector}} =
          ExLLM.Providers.Gemini.Embeddings.embed_text("models/text-embedding-004", query)

        Repo.all(
          from book in Book,
            order_by: l2_distance(book.embedding, ^Pgvector.new(vector)),
            limit: 10
        )
      end

    {:noreply, socket |> stream(:books, books, reset: true)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Books
        <:actions>
          <.button variant="primary" navigate={~p"/books/new"}>
            <.icon name="hero-plus" /> New Book
          </.button>
        </:actions>
      </.header>

      <.form
        for={@search_form}
        id="search-form"
        phx-submit="search"
      >
        <.input field={@search_form[:query]} type="text" />
        <.button phx-disable-with="..." variant="primary">Search</.button>
      </.form>

      <.table
        id="books"
        rows={@streams.books}
        row_click={fn {_id, book} -> JS.navigate(~p"/books/#{book}") end}
      >
        <:col :let={{_id, book}} label="#">
          <.icon :if={book.is_available} name="hero-check" class="size-5 text-green-500" />
          <.icon :if={!book.is_available} name="hero-no-symbol" class="size-5 text-red-500" />
        </:col>
        <:col :let={{_id, book}} label="Name">
          <div class="group hover:ring ring-primary rounded p-1">
            {book.name}
            <div class="invisible rounded-lg p-4 absolute group-hover:visible right-0 z-50 left-1/3 bg-info-content text-info shadow-xl">
              {book.description}
            </div>
          </div>
        </:col>
        <:col :let={{_id, book}} label="Author">{book.author}</:col>
        <:col :let={{_id, book}} label="Published at">{book.published_at}</:col>
        <:col :let={{_id, book}} label="Price">{book.price}</:col>
        <:action :let={{_id, book}}>
          <div class="sr-only">
            <.link navigate={~p"/books/#{book}"}>Show</.link>
          </div>
          <.link navigate={~p"/books/#{book}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, book}}>
          <.link
            phx-click={JS.push("delete", value: %{id: book.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end
end
