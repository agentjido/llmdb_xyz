defmodule PetalBoilerplate.Subscriptions do
  @moduledoc """
  Static catalog of coding subscription plans used by the subscription value calculator.
  """

  @last_verified ~D[2026-02-28]

  @plans [
    %{
      id: "openai_plus",
      provider: "OpenAI",
      name: "ChatGPT Plus",
      monthly_price_usd: 20.0,
      limit_type: :hard_numeric,
      primary_unit: :messages,
      reset_window: :rolling_5h,
      included_min: 45.0,
      included_max: 225.0,
      model_options: [
        %{spec: "openai:gpt-5.1-codex-mini", tier: :budget},
        %{spec: "openai:gpt-5.1-codex", tier: :balanced},
        %{spec: "openai:gpt-5.3-codex", tier: :premium}
      ],
      source_urls: [
        "https://developers.openai.com/codex/pricing",
        "https://openai.com/business/chatgpt-pricing/"
      ],
      last_verified_on: @last_verified,
      confidence_default: :high
    },
    %{
      id: "openai_pro",
      provider: "OpenAI",
      name: "ChatGPT Pro",
      monthly_price_usd: 200.0,
      limit_type: :hard_numeric,
      primary_unit: :messages,
      reset_window: :rolling_5h,
      included_min: 300.0,
      included_max: 1500.0,
      model_options: [
        %{spec: "openai:gpt-5.1-codex-mini", tier: :budget},
        %{spec: "openai:gpt-5.1-codex", tier: :balanced},
        %{spec: "openai:gpt-5.3-codex", tier: :premium}
      ],
      source_urls: [
        "https://developers.openai.com/codex/pricing",
        "https://openai.com/business/chatgpt-pricing/"
      ],
      last_verified_on: @last_verified,
      confidence_default: :high
    },
    %{
      id: "openai_business",
      provider: "OpenAI",
      name: "ChatGPT Business",
      monthly_price_usd: 30.0,
      limit_type: :hard_numeric,
      primary_unit: :messages,
      reset_window: :rolling_5h,
      included_min: 45.0,
      included_max: 225.0,
      model_options: [
        %{spec: "openai:gpt-5.1-codex-mini", tier: :budget},
        %{spec: "openai:gpt-5.1-codex", tier: :balanced},
        %{spec: "openai:gpt-5.3-codex", tier: :premium}
      ],
      source_urls: [
        "https://developers.openai.com/codex/pricing",
        "https://openai.com/business/chatgpt-pricing/"
      ],
      last_verified_on: @last_verified,
      confidence_default: :high
    },
    %{
      id: "openai_enterprise_edu",
      provider: "OpenAI",
      name: "ChatGPT Enterprise & Edu",
      monthly_price_usd: nil,
      limit_type: :opaque,
      primary_unit: :credits,
      reset_window: :mixed,
      included_min: nil,
      included_max: nil,
      model_options: [
        %{spec: "openai:gpt-5.1-codex-mini", tier: :budget},
        %{spec: "openai:gpt-5.1-codex", tier: :balanced},
        %{spec: "openai:gpt-5.3-codex", tier: :premium}
      ],
      source_urls: [
        "https://developers.openai.com/codex/pricing",
        "https://openai.com/business/chatgpt-pricing/"
      ],
      last_verified_on: @last_verified,
      confidence_default: :low
    },
    %{
      id: "anthropic_pro",
      provider: "Anthropic",
      name: "Claude Pro",
      monthly_price_usd: 20.0,
      limit_type: :multiplier,
      primary_unit: :messages,
      reset_window: :rolling_5h,
      included_min: nil,
      included_max: nil,
      model_options: [
        %{spec: "anthropic:claude-haiku-4-5-20251001", tier: :budget},
        %{spec: "anthropic:claude-sonnet-4-5-20250929", tier: :balanced},
        %{spec: "anthropic:claude-opus-4-5-20251101", tier: :premium}
      ],
      source_urls: [
        "https://support.claude.com/en/articles/8325606-what-is-the-pro-plan",
        "https://support.claude.com/en/articles/11145838-using-claude-code-with-your-pro-or-max-plan"
      ],
      last_verified_on: @last_verified,
      confidence_default: :low
    },
    %{
      id: "anthropic_max_5x",
      provider: "Anthropic",
      name: "Claude Max 5x",
      monthly_price_usd: 100.0,
      limit_type: :multiplier,
      primary_unit: :messages,
      reset_window: :rolling_5h,
      included_min: 225.0,
      included_max: 750.0,
      model_options: [
        %{spec: "anthropic:claude-haiku-4-5-20251001", tier: :budget},
        %{spec: "anthropic:claude-sonnet-4-5-20250929", tier: :balanced},
        %{spec: "anthropic:claude-opus-4-5-20251101", tier: :premium}
      ],
      source_urls: [
        "https://support.claude.com/en/articles/11049741-what-is-the-max-plan",
        "https://support.claude.com/en/articles/11014257-about-claude-s-max-plan-usage"
      ],
      last_verified_on: @last_verified,
      confidence_default: :medium
    },
    %{
      id: "anthropic_max_20x",
      provider: "Anthropic",
      name: "Claude Max 20x",
      monthly_price_usd: 200.0,
      limit_type: :hard_numeric,
      primary_unit: :messages,
      reset_window: :rolling_5h,
      included_min: 900.0,
      included_max: 1800.0,
      model_options: [
        %{spec: "anthropic:claude-haiku-4-5-20251001", tier: :budget},
        %{spec: "anthropic:claude-sonnet-4-5-20250929", tier: :balanced},
        %{spec: "anthropic:claude-opus-4-5-20251101", tier: :premium}
      ],
      source_urls: [
        "https://support.claude.com/en/articles/11049741-what-is-the-max-plan",
        "https://support.claude.com/en/articles/11014257-about-claude-s-max-plan-usage",
        "https://support.claude.com/en/articles/12429409-extra-usage-for-paid-claude-plans"
      ],
      last_verified_on: @last_verified,
      confidence_default: :medium
    },
    %{
      id: "cursor_pro",
      provider: "Cursor",
      name: "Cursor Pro",
      monthly_price_usd: 20.0,
      limit_type: :opaque,
      primary_unit: :mixed,
      reset_window: :mixed,
      included_min: nil,
      included_max: nil,
      model_options: [
        %{spec: "openai:gpt-5.1-codex-mini", tier: :budget},
        %{spec: "anthropic:claude-sonnet-4-5-20250929", tier: :balanced},
        %{spec: "openai:gpt-5.3-codex", tier: :premium}
      ],
      source_urls: ["https://cursor.com/pricing"],
      last_verified_on: @last_verified,
      confidence_default: :low
    },
    %{
      id: "cursor_pro_plus",
      provider: "Cursor",
      name: "Cursor Pro+",
      monthly_price_usd: 60.0,
      limit_type: :opaque,
      primary_unit: :mixed,
      reset_window: :mixed,
      included_min: nil,
      included_max: nil,
      model_options: [
        %{spec: "openai:gpt-5.1-codex-mini", tier: :budget},
        %{spec: "anthropic:claude-sonnet-4-5-20250929", tier: :balanced},
        %{spec: "openai:gpt-5.3-codex", tier: :premium}
      ],
      source_urls: ["https://cursor.com/pricing"],
      last_verified_on: @last_verified,
      confidence_default: :low
    },
    %{
      id: "cursor_ultra",
      provider: "Cursor",
      name: "Cursor Ultra",
      monthly_price_usd: 200.0,
      limit_type: :opaque,
      primary_unit: :mixed,
      reset_window: :mixed,
      included_min: nil,
      included_max: nil,
      model_options: [
        %{spec: "openai:gpt-5.1-codex-mini", tier: :budget},
        %{spec: "anthropic:claude-sonnet-4-5-20250929", tier: :balanced},
        %{spec: "openai:gpt-5.3-codex", tier: :premium}
      ],
      source_urls: ["https://cursor.com/pricing"],
      last_verified_on: @last_verified,
      confidence_default: :low
    },
    %{
      id: "github_copilot_pro",
      provider: "GitHub",
      name: "GitHub Copilot Pro",
      monthly_price_usd: 10.0,
      limit_type: :opaque,
      primary_unit: :mixed,
      reset_window: :monthly,
      included_min: nil,
      included_max: nil,
      model_options: [
        %{spec: "openai:gpt-5.1-codex-mini", tier: :budget},
        %{spec: "openai:gpt-5.1-codex", tier: :balanced},
        %{spec: "anthropic:claude-sonnet-4-5-20250929", tier: :premium}
      ],
      source_urls: [
        "https://github.com/features/copilot/plans",
        "https://docs.github.com/en/copilot/get-started/plans"
      ],
      last_verified_on: @last_verified,
      confidence_default: :low
    },
    %{
      id: "github_copilot_pro_plus",
      provider: "GitHub",
      name: "GitHub Copilot Pro+",
      monthly_price_usd: 39.0,
      limit_type: :opaque,
      primary_unit: :mixed,
      reset_window: :monthly,
      included_min: nil,
      included_max: nil,
      model_options: [
        %{spec: "openai:gpt-5.1-codex-mini", tier: :budget},
        %{spec: "openai:gpt-5.1-codex", tier: :balanced},
        %{spec: "anthropic:claude-sonnet-4-5-20250929", tier: :premium}
      ],
      source_urls: [
        "https://github.com/features/copilot/plans",
        "https://docs.github.com/en/copilot/get-started/plans"
      ],
      last_verified_on: @last_verified,
      confidence_default: :low
    },
    %{
      id: "windsurf_pro",
      provider: "Windsurf",
      name: "Windsurf Pro",
      monthly_price_usd: 15.0,
      limit_type: :opaque,
      primary_unit: :mixed,
      reset_window: :mixed,
      included_min: nil,
      included_max: nil,
      model_options: [
        %{spec: "openai:gpt-5.1-codex-mini", tier: :budget},
        %{spec: "anthropic:claude-sonnet-4-5-20250929", tier: :balanced},
        %{spec: "openai:gpt-5.3-codex", tier: :premium}
      ],
      source_urls: ["https://windsurf.com/pricing"],
      last_verified_on: @last_verified,
      confidence_default: :low
    },
    %{
      id: "amazon_q_developer_pro",
      provider: "Amazon",
      name: "Amazon Q Developer Pro",
      monthly_price_usd: 19.0,
      limit_type: :opaque,
      primary_unit: :mixed,
      reset_window: :monthly,
      included_min: nil,
      included_max: nil,
      model_options: [
        %{spec: "anthropic:claude-haiku-4-5-20251001", tier: :budget},
        %{spec: "anthropic:claude-sonnet-4-5-20250929", tier: :balanced},
        %{spec: "anthropic:claude-opus-4-5-20251101", tier: :premium}
      ],
      source_urls: ["https://aws.amazon.com/q/developer/pricing"],
      last_verified_on: @last_verified,
      confidence_default: :low
    },
    %{
      id: "google_ai_pro",
      provider: "Google",
      name: "Google AI Pro",
      monthly_price_usd: 20.0,
      limit_type: :opaque,
      primary_unit: :mixed,
      reset_window: :monthly,
      included_min: nil,
      included_max: nil,
      model_options: [
        %{spec: "google:gemini-2.5-flash-lite", tier: :budget},
        %{spec: "google:gemini-2.5-flash", tier: :balanced},
        %{spec: "google:gemini-2.5-pro", tier: :premium}
      ],
      source_urls: [
        "https://one.google.com/about/plans",
        "https://developers.google.com/gemini-code-assist/resources/faqs"
      ],
      last_verified_on: @last_verified,
      confidence_default: :low
    },
    %{
      id: "google_ai_ultra",
      provider: "Google",
      name: "Google AI Ultra",
      monthly_price_usd: 250.0,
      limit_type: :opaque,
      primary_unit: :mixed,
      reset_window: :monthly,
      included_min: nil,
      included_max: nil,
      model_options: [
        %{spec: "google:gemini-2.5-flash-lite", tier: :budget},
        %{spec: "google:gemini-2.5-flash", tier: :balanced},
        %{spec: "google:gemini-2.5-pro", tier: :premium}
      ],
      source_urls: ["https://one.google.com/about/plans"],
      last_verified_on: @last_verified,
      confidence_default: :low
    },
    %{
      id: "google_code_assist_standard",
      provider: "Google",
      name: "Gemini Code Assist Standard",
      monthly_price_usd: 19.0,
      limit_type: :opaque,
      primary_unit: :messages,
      reset_window: :monthly,
      included_min: nil,
      included_max: nil,
      model_options: [
        %{spec: "google:gemini-2.5-flash-lite", tier: :budget},
        %{spec: "google:gemini-2.5-flash", tier: :balanced},
        %{spec: "google:gemini-2.5-pro", tier: :premium}
      ],
      source_urls: [
        "https://cloud.google.com/gemini/docs/codeassist/overview",
        "https://developers.google.com/gemini-code-assist/resources/faqs"
      ],
      last_verified_on: @last_verified,
      confidence_default: :low
    },
    %{
      id: "jetbrains_ai_pro",
      provider: "JetBrains",
      name: "JetBrains AI Pro",
      monthly_price_usd: 10.0,
      limit_type: :opaque,
      primary_unit: :credits,
      reset_window: :monthly,
      included_min: nil,
      included_max: nil,
      model_options: [
        %{spec: "openai:gpt-5.1-codex-mini", tier: :budget},
        %{spec: "openai:gpt-5.1-codex", tier: :balanced},
        %{spec: "anthropic:claude-sonnet-4-5-20250929", tier: :premium}
      ],
      source_urls: [
        "https://www.jetbrains.com/help/ai-assistant/licensing-and-subscriptions.html"
      ],
      last_verified_on: @last_verified,
      confidence_default: :low
    },
    %{
      id: "jetbrains_ai_ultimate",
      provider: "JetBrains",
      name: "JetBrains AI Ultimate",
      monthly_price_usd: 60.0,
      limit_type: :opaque,
      primary_unit: :credits,
      reset_window: :monthly,
      included_min: nil,
      included_max: nil,
      model_options: [
        %{spec: "openai:gpt-5.1-codex-mini", tier: :budget},
        %{spec: "openai:gpt-5.1-codex", tier: :balanced},
        %{spec: "anthropic:claude-sonnet-4-5-20250929", tier: :premium}
      ],
      source_urls: [
        "https://www.jetbrains.com/help/ai-assistant/licensing-and-subscriptions.html"
      ],
      last_verified_on: @last_verified,
      confidence_default: :low
    },
    %{
      id: "mistral_le_chat_pro",
      provider: "Mistral",
      name: "Mistral Le Chat Pro",
      monthly_price_usd: 15.0,
      limit_type: :opaque,
      primary_unit: :messages,
      reset_window: :monthly,
      included_min: nil,
      included_max: nil,
      model_options: [
        %{spec: "mistral:mistral-small-latest", tier: :budget},
        %{spec: "mistral:mistral-medium-latest", tier: :balanced},
        %{spec: "mistral:pixtral-large-latest", tier: :premium}
      ],
      source_urls: ["https://mistral.ai/pricing"],
      last_verified_on: @last_verified,
      confidence_default: :low
    },
    %{
      id: "xai_x_premium_plus",
      provider: "xAI",
      name: "X Premium+",
      monthly_price_usd: 40.0,
      limit_type: :opaque,
      primary_unit: :messages,
      reset_window: :monthly,
      included_min: nil,
      included_max: nil,
      model_options: [
        %{spec: "xai:grok-3-mini-fast-latest", tier: :budget},
        %{spec: "xai:grok-4-fast", tier: :balanced},
        %{spec: "xai:grok-4-1-fast", tier: :premium}
      ],
      source_urls: [
        "https://x.ai/news",
        "https://help.x.com"
      ],
      last_verified_on: @last_verified,
      confidence_default: :low
    },
    %{
      id: "xai_supergrok",
      provider: "xAI",
      name: "SuperGrok",
      monthly_price_usd: 30.0,
      limit_type: :opaque,
      primary_unit: :messages,
      reset_window: :monthly,
      included_min: nil,
      included_max: nil,
      model_options: [
        %{spec: "xai:grok-3-mini-fast-latest", tier: :budget},
        %{spec: "xai:grok-4-fast", tier: :balanced},
        %{spec: "xai:grok-4-1-fast", tier: :premium}
      ],
      source_urls: ["https://x.ai/news"],
      last_verified_on: @last_verified,
      confidence_default: :low
    },
    %{
      id: "zai_pro",
      provider: "Z.ai",
      name: "Z.ai Pro",
      monthly_price_usd: 20.0,
      limit_type: :opaque,
      primary_unit: :messages,
      reset_window: :monthly,
      included_min: nil,
      included_max: nil,
      model_options: [
        %{spec: "openai:gpt-5.1-codex-mini", tier: :budget},
        %{spec: "openai:gpt-5.1-codex", tier: :balanced},
        %{spec: "anthropic:claude-sonnet-4-5-20250929", tier: :premium}
      ],
      source_urls: ["https://z.ai"],
      last_verified_on: @last_verified,
      confidence_default: :low
    },
    %{
      id: "replit_core",
      provider: "Replit",
      name: "Replit Core",
      monthly_price_usd: 20.0,
      limit_type: :opaque,
      primary_unit: :credits,
      reset_window: :monthly,
      included_min: nil,
      included_max: nil,
      model_options: [
        %{spec: "openai:gpt-5.1-codex-mini", tier: :budget},
        %{spec: "anthropic:claude-sonnet-4-5-20250929", tier: :balanced},
        %{spec: "openai:gpt-5.3-codex", tier: :premium}
      ],
      source_urls: ["https://replit.com/pricing"],
      last_verified_on: @last_verified,
      confidence_default: :low
    },
    %{
      id: "perplexity_pro",
      provider: "Perplexity",
      name: "Perplexity Pro",
      monthly_price_usd: 20.0,
      limit_type: :opaque,
      primary_unit: :messages,
      reset_window: :monthly,
      included_min: nil,
      included_max: nil,
      model_options: [
        %{spec: "openai:gpt-5.1-codex-mini", tier: :budget},
        %{spec: "anthropic:claude-sonnet-4-5-20250929", tier: :balanced},
        %{spec: "openai:gpt-5.3-codex", tier: :premium}
      ],
      source_urls: ["https://www.perplexity.ai/pro"],
      last_verified_on: @last_verified,
      confidence_default: :low
    }
  ]

  @doc """
  Returns all known subscription plans.
  """
  def all_plans do
    @plans
  end

  @doc """
  Returns plans ordered for checkbox selection.
  """
  def plans_for_selection do
    @plans
    |> Enum.sort_by(fn plan -> {plan.provider, plan.name} end)
  end

  @doc """
  Returns plan by id or nil.
  """
  def get_plan(plan_id) when is_binary(plan_id) do
    Enum.find(@plans, &(&1.id == plan_id))
  end

  @doc """
  Returns plans for the provided ids preserving input order.
  """
  def selected_plans(plan_ids) when is_list(plan_ids) do
    plan_ids
    |> Enum.map(&get_plan/1)
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  Default plan ids selected on first load.
  """
  def default_selected_plan_ids do
    ["openai_pro", "openai_plus", "anthropic_max_20x", "anthropic_max_5x"]
  end
end
