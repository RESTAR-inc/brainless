# Brainless

Create `.env` file (see `.env.example`)

1. You need to obtain a [Gemini API key](https://aistudio.google.com/api-keys). Put it into `GOOGLE_API_KEY` in your environment
2. Run migration `$ mix ecto.migrate`
3. Seed the database `$ mix seed`
4. Build index `$ mix build_index`

Now you can start the server. Check `/movies` route

## Datasets

- [Tokyo Restaurant Reviews on Tabelog](https://www.kaggle.com/datasets/utm529fg/tokyo-restaurant-reviews-on-tabelog)
- [Shibuya Toilet](https://www.kaggle.com/datasets/shunkogiso/toilet-shibuya)

## Models

### List of compatible models with 768 dimensions

- sentence-transformers/gtr-t5-base (~220 MB, english only)
- sentence-transformers/LaBSE (~1.9 GB, multilang)
- sentence-transformers/distiluse-base-multilingual-cased-v2 (~540 MB, multilang)
- sentence-transformers/paraphrase-multilingual-mpnet-base-v2 (~1.1 GB, multilang)
