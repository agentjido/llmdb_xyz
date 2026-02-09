defmodule PetalBoilerplateWeb.AboutLive do
  use PetalBoilerplateWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "About",
       page_description:
         "Learn about llmdb.xyz - a comprehensive database of 2,000+ LLM models. Powered by the open-source llm_db Elixir package.",
       og_url: "https://llmdb.xyz/about",
       og_image: "https://llmdb.xyz/og/about.png"
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col" style="background-color: hsl(var(--background));">
      <PetalBoilerplateWeb.ModelComponents.header search_value="" />

      <div class="flex-1 w-full max-w-4xl mx-auto py-8 sm:py-12 px-4 sm:px-6">
        <h1 class="text-3xl sm:text-4xl font-bold mb-6" style="color: hsl(var(--foreground));">
          About llmdb.xyz
        </h1>

        <div
          class="rounded-lg border p-6 mb-6"
          style="border-color: hsl(var(--border)); background-color: hsl(var(--card));"
        >
          <h2 class="text-xl font-semibold mb-4" style="color: hsl(var(--foreground));">
            What is this?
          </h2>
          <p class="mb-4" style="color: hsl(var(--muted-foreground));">
            llmdb.xyz is a comprehensive database of Large Language Models (LLMs) from all major providers.
            Browse, filter, and compare models by capabilities, pricing, context windows, and more.
          </p>
          <p class="mb-4" style="color: hsl(var(--muted-foreground));">
            This site is powered by <a
              href="https://hex.pm/packages/llm_db"
              target="_blank"
              rel="noopener noreferrer"
              class="hover:underline"
              style="color: hsl(var(--primary));"
            >llm_db</a>, an open-source Elixir package that provides a unified interface
            for querying LLM model metadata across providers.
          </p>
          <p style="color: hsl(var(--muted-foreground));">
            The llm_db package is designed to power <a
              href="https://hex.pm/packages/req_llm"
              target="_blank"
              rel="noopener noreferrer"
              class="hover:underline"
              style="color: hsl(var(--primary));"
            >req_llm</a>, a comprehensive Elixir AI API client that provides a unified interface
            for interacting with OpenAI, Anthropic, Google, Mistral, and many other LLM providers.
          </p>
        </div>

        <div
          class="rounded-lg border p-6 mb-6"
          style="border-color: hsl(var(--border)); background-color: hsl(var(--card));"
        >
          <h2 class="text-xl font-semibold mb-4" style="color: hsl(var(--foreground));">
            Features
          </h2>
          <ul class="space-y-2 list-disc list-inside" style="color: hsl(var(--muted-foreground));">
            <li>Browse 2,000+ models from OpenAI, Anthropic, Google, Mistral, and more</li>
            <li>Filter by capabilities: chat, embeddings, reasoning, tool use, streaming</li>
            <li>Compare pricing across providers</li>
            <li>View context windows and output limits</li>
            <li>Filter by input/output modalities (text, image, audio)</li>
            <li>Dark mode support</li>
          </ul>
        </div>

        <div
          class="rounded-lg border p-6 mb-6"
          style="border-color: hsl(var(--border)); background-color: hsl(var(--card));"
        >
          <h2 class="text-xl font-semibold mb-4" style="color: hsl(var(--foreground));">
            Data Sources
          </h2>
          <p class="mb-4" style="color: hsl(var(--muted-foreground));">
            The llm_db package aggregates model metadata from multiple sources to build a comprehensive catalog
            spanning 127+ providers. Data is collected through a build-time ETL pipeline that ingests, normalizes,
            validates, and merges records from each source:
          </p>
          <ul
            class="space-y-2 list-disc list-inside mb-4"
            style="color: hsl(var(--muted-foreground));"
          >
            <li>
              <a
                href="https://models.dev"
                target="_blank"
                rel="noopener noreferrer"
                class="hover:underline"
                style="color: hsl(var(--primary));"
              >
                models.dev
              </a>
              &mdash; community-maintained model catalog with pricing, context limits, and capabilities
            </li>
            <li>
              <a
                href="https://platform.openai.com/docs/api-reference/models"
                target="_blank"
                rel="noopener noreferrer"
                class="hover:underline"
                style="color: hsl(var(--primary));"
              >
                OpenAI Models API
              </a>
              &mdash; official model list directly from OpenAI
            </li>
            <li>
              <a
                href="https://docs.anthropic.com/en/api/models"
                target="_blank"
                rel="noopener noreferrer"
                class="hover:underline"
                style="color: hsl(var(--primary));"
              >
                Anthropic Models API
              </a>
              &mdash; official model list directly from Anthropic
            </li>
            <li>
              <a
                href="https://ai.google.dev/gemini-api/docs/models"
                target="_blank"
                rel="noopener noreferrer"
                class="hover:underline"
                style="color: hsl(var(--primary));"
              >
                Google Gemini API
              </a>
              &mdash; official model list from Google
            </li>
            <li>
              <a
                href="https://docs.x.ai/api"
                target="_blank"
                rel="noopener noreferrer"
                class="hover:underline"
                style="color: hsl(var(--primary));"
              >
                xAI API
              </a>
              &mdash; official model list from xAI
            </li>
            <li>
              <a
                href="https://openrouter.ai"
                target="_blank"
                rel="noopener noreferrer"
                class="hover:underline"
                style="color: hsl(var(--primary));"
              >
                OpenRouter
              </a>
              &mdash; aggregated model catalog across dozens of providers
            </li>
            <li>Hand-curated local TOML overrides for corrections and additional metadata</li>
          </ul>
          <p style="color: hsl(var(--muted-foreground));">
            Sources are merged with a last-wins precedence strategy, allowing hand-curated data
            to override upstream records where needed.
          </p>
        </div>

        <div
          class="rounded-lg border p-6 mb-6"
          style="border-color: hsl(var(--border)); background-color: hsl(var(--card));"
        >
          <h2 class="text-xl font-semibold mb-4" style="color: hsl(var(--foreground));">
            Acknowledgements
          </h2>
          <p class="mb-4" style="color: hsl(var(--muted-foreground));">
            Special thanks to the
            <a
              href="https://models.dev"
              target="_blank"
              rel="noopener noreferrer"
              class="hover:underline font-semibold"
              style="color: hsl(var(--primary));"
            >
              models.dev
            </a>
            project for maintaining an open, community-driven catalog of LLM model metadata.
            Their comprehensive dataset serves as a foundational data source for llm_db and makes
            projects like this one possible.
          </p>
        </div>

        <div
          class="rounded-lg border p-6 mb-6"
          style="border-color: hsl(var(--border)); background-color: hsl(var(--card));"
        >
          <h2 class="text-xl font-semibold mb-4" style="color: hsl(var(--foreground));">
            Open Source
          </h2>
          <p class="mb-4" style="color: hsl(var(--muted-foreground));">
            Both this website and the underlying llm_db package are open source.
          </p>
          <div class="flex flex-wrap gap-4">
            <a
              href="https://github.com/agentjido/llm_db"
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex items-center gap-2 px-4 py-2 rounded-lg transition-colors hover:opacity-80"
              style="background-color: hsl(var(--primary)); color: hsl(var(--primary-foreground));"
            >
              <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                <path
                  fill-rule="evenodd"
                  d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z"
                  clip-rule="evenodd"
                />
              </svg>
              llm_db on GitHub
            </a>
            <a
              href="https://hex.pm/packages/llm_db"
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex items-center gap-2 px-4 py-2 rounded-lg transition-colors hover:opacity-80"
              style="background-color: hsl(var(--secondary)); color: hsl(var(--secondary-foreground));"
            >
              <svg class="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
                <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5" />
              </svg>
              llm_db on Hex.pm
            </a>
          </div>
        </div>

        <div
          class="rounded-lg border p-6 mb-6"
          style="border-color: hsl(var(--border)); background-color: hsl(var(--card));"
        >
          <h2 class="text-xl font-semibold mb-4" style="color: hsl(var(--foreground));">
            Author
          </h2>
          <p class="mb-4" style="color: hsl(var(--muted-foreground));">
            Built by <span class="font-semibold" style="color: hsl(var(--foreground));">Mike Hostetler</span>.
            Found a bug or have a suggestion? Please <a
              href="https://github.com/agentjido/llmdb_xyz/issues"
              target="_blank"
              rel="noopener noreferrer"
              class="hover:underline"
              style="color: hsl(var(--primary));"
            >submit an issue on GitHub</a>.
          </p>
          <div class="flex flex-wrap gap-4">
            <a
              href="https://github.com/mikehostetler"
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex items-center gap-2 px-4 py-2 rounded-lg transition-colors hover:opacity-80"
              style="background-color: hsl(var(--primary)); color: hsl(var(--primary-foreground));"
            >
              <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                <path
                  fill-rule="evenodd"
                  d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z"
                  clip-rule="evenodd"
                />
              </svg>
              GitHub
            </a>
            <a
              href="https://mike-hostetler.com"
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex items-center gap-2 px-4 py-2 rounded-lg transition-colors hover:opacity-80"
              style="background-color: hsl(var(--secondary)); color: hsl(var(--secondary-foreground));"
            >
              <svg
                class="w-5 h-5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                stroke-width="2"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M12 21a9.004 9.004 0 008.716-6.747M12 21a9.004 9.004 0 01-8.716-6.747M12 21c2.485 0 4.5-4.03 4.5-9S14.485 3 12 3m0 18c-2.485 0-4.5-4.03-4.5-9S9.515 3 12 3m0 0a8.997 8.997 0 017.843 4.582M12 3a8.997 8.997 0 00-7.843 4.582m15.686 0A11.953 11.953 0 0112 10.5c-2.998 0-5.74-1.1-7.843-2.918m15.686 0A8.959 8.959 0 0121 12c0 .778-.099 1.533-.284 2.253m0 0A17.919 17.919 0 0112 16.5c-3.162 0-6.133-.815-8.716-2.247m0 0A9.015 9.015 0 003 12c0-1.605.42-3.113 1.157-4.418"
                />
              </svg>
              Website
            </a>
          </div>
        </div>

        <div
          class="rounded-lg border p-6"
          style="border-color: hsl(var(--border)); background-color: hsl(var(--card));"
        >
          <h2 class="text-xl font-semibold mb-4" style="color: hsl(var(--foreground));">
            Community
          </h2>
          <p class="mb-4" style="color: hsl(var(--muted-foreground));">
            Join us on Discord to discuss LLMs, share feedback, or contribute to the project.
          </p>
          <a
            href="https://agentjido.xyz/discord"
            target="_blank"
            rel="noopener noreferrer"
            class="inline-flex items-center gap-2 px-4 py-2 rounded-lg transition-colors hover:opacity-80"
            style="background-color: hsl(var(--primary)); color: hsl(var(--primary-foreground));"
          >
            <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
              <path d="M20.317 4.37a19.791 19.791 0 0 0-4.885-1.515.074.074 0 0 0-.079.037c-.21.375-.444.864-.608 1.25a18.27 18.27 0 0 0-5.487 0 12.64 12.64 0 0 0-.617-1.25.077.077 0 0 0-.079-.037A19.736 19.736 0 0 0 3.677 4.37a.07.07 0 0 0-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 0 0 .031.057 19.9 19.9 0 0 0 5.993 3.03.078.078 0 0 0 .084-.028 14.09 14.09 0 0 0 1.226-1.994.076.076 0 0 0-.041-.106 13.107 13.107 0 0 1-1.872-.892.077.077 0 0 1-.008-.128 10.2 10.2 0 0 0 .372-.292.074.074 0 0 1 .077-.01c3.928 1.793 8.18 1.793 12.062 0a.074.074 0 0 1 .078.01c.12.098.246.198.373.292a.077.077 0 0 1-.006.127 12.299 12.299 0 0 1-1.873.892.077.077 0 0 0-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 0 0 .084.028 19.839 19.839 0 0 0 6.002-3.03.077.077 0 0 0 .032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.03zM8.02 15.33c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.956-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.956 2.418-2.157 2.418zm7.975 0c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.955-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.946 2.418-2.157 2.418z" />
            </svg>
            Join Discord
          </a>
        </div>
      </div>
    </div>
    """
  end
end
