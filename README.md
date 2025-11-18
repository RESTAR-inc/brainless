# Brainless

Create `.env` file (see `.env.example`)

1. You need to obtain a [Gemini API key](https://aistudio.google.com/api-keys). Put it into `GOOGLE_API_KEY` in your environment
2. Run migration `$ mix ecto.migrate`
3. Seed the database `$ mix seed`
4. Build index `$ mix build_index`

Now you can start the server. Check `/movies` route
