# Brainless

## Requirements

You need to set up the embedding server from here: https://github.com/RESTAR-inc/brainless_embedding_service

After that set env variables:

- RAG_SERVICE_URL
- RAG_SERVICE_API_KEY (use the same key as in `brainless_embedding_service`)

## Howto

Create `.env` file (see `.env.example`)

1. Instal dependencies `$ mix deps.get`
2. Run docker containers `$ docker compose up -d`
3. Run migration `$ mix ecto.migrate`
4. Seed the database `$ mix media_library.seed`
5. Build index `$ mix build_index`
6. Start the application `$ mix phx.server`

Now you can start the server. Check `/media` route

(Optional)

If you want to use `gemini` to build the index, you need to obtain a [Gemini API Key](https://aistudio.google.com/api-keys). Put it into `GOOGLE_API_KEY` in your environment.

You can switch to Gemini by changing the config:

```elixir
config :brainless, Brainless.Rag, embedding_provider: :gemini,
```

## How it works

### Indexing Flow

```mermaid
sequenceDiagram
    box rgba(125, 125, 125, 0.1) Application
        participant App
        participant DB@{type: database }
        participant ElasticSearch@{type: database }
    end

    box rgba(125, 125, 0, 0.1) Rag Service
        participant RAG_AS as API Server
        participant EmbeddingModel@{type: entity}
    end

    App ->> DB: Query all
    DB ->> App: Collect the data
    App ->> App: Create raw [IndexData]
    App -->> RAG_AS: Send [{Id, Text}]
    RAG_AS ->> EmbeddingModel: Bulk Send [Text]
    EmbeddingModel ->> RAG_AS: Bulk Create [{Id, Vector}]
    RAG_AS -->> App: Recreate [{IndexData, Vector}]
    App ->> ElasticSearch: Put to index
```

### Search Flow

```mermaid
sequenceDiagram
    actor User

    box rgba(125, 125, 125, 0.1) Application
        participant App
        participant DB@{type: database }
        participant ElasticSearch@{type: database }
    end

    box rgba(125, 125, 0, 0.1) Rag Service
        participant RAG_AS as API Server
        participant EmbeddingModel@{type: entity}
    end

    box rgba(0, 125, 125, 0.1) LLM
        participant RerankingModel@{type: entity}
    end

    User ->> App: Search request
    App -->> RAG_AS: Transform text to a vector
    RAG_AS ->> EmbeddingModel: Text
    EmbeddingModel ->> RAG_AS: Vector
    RAG_AS -->> App: Vector
    App ->> ElasticSearch: Do search
    ElasticSearch ->> App: IndexData[]
    App -->> RAG_AS: Extract document+id
    RAG_AS -->> RerankingModel: Send list of documents
    RerankingModel -->> RAG_AS: Reranked documents
    RAG_AS -->> App: Recreate IndexData[] with reranked documents
    App ->> DB: Search DB with ids from IndexData[]
    DB ->> App: Records from DB
    App ->> User: Show list of results
```
