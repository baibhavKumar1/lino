import os
from typing import Optional, List, Dict, Any
from deepeval.models.base_model import DeepEvalBaseLLM
from openai import OpenAI

DEFAULT_OPENROUTER_KEY = "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"
DEFAULT_BASE_URL = "https://openrouter.ai/api/v1"

# Fast Verified 100% Free Zero-Cost ($0.00) Live Endpoints on OpenRouter (matching openrouter_client.dart)
FREE_MODELS: List[str] = [
    "google/gemma-4-26b-a4b-it:free",
    "nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free",
    "openrouter/free",
    "thinkingmachines/inkling-small:free",
]

# Previous paid judge logic:
# DEFAULT_EVAL_JUDGE_MODEL = "anthropic/claude-3.7-sonnet"
# New free-tier judge and target models:
DEFAULT_EVAL_JUDGE_MODEL = "google/gemma-4-26b-a4b-it:free"
DEFAULT_TARGET_MODEL = "google/gemma-4-26b-a4b-it:free"

class OpenRouterModel(DeepEvalBaseLLM):
    """
    Production OpenRouter integration for DeepEval using 100% Free models.
    Supports automatic fallback across candidate free models matching OpenRouterClient in Dart.
    """

    def __init__(
        self,
        model_name: Optional[str] = None,
        api_key: Optional[str] = None,
        base_url: Optional[str] = None,
        temperature: float = 0.0,
        max_tokens: int = 2200,
        candidate_models: Optional[List[str]] = None,
    ):
        self.model_name = model_name or os.environ.get("TARGET_MODEL", DEFAULT_TARGET_MODEL)
        self.api_key = api_key or os.environ.get("OPENROUTER_API_KEY", DEFAULT_OPENROUTER_KEY)
        self.base_url = base_url or os.environ.get("OPENROUTER_BASE_URL", DEFAULT_BASE_URL)
        self.temperature = temperature
        self.max_tokens = max_tokens
        
        # Build candidate fallback list prioritizing the chosen model
        base_list = candidate_models or FREE_MODELS
        if self.model_name in base_list:
            self.candidates = [self.model_name] + [m for m in base_list if m != self.model_name]
        else:
            self.candidates = [self.model_name] + base_list

        self.client = OpenAI(
            base_url=self.base_url,
            api_key=self.api_key,
            default_headers={
                "HTTP-Referer": "https://kichook.app",
                "X-Title": "Kichook Agent Evaluation Suite",
            },
        )

    def load_model(self):
        return self.client

    def generate(self, prompt: str) -> str:
        """
        Synchronous prompt completion via OpenRouter with automatic candidate fallback
        across verified 100% free models.
        """
        last_error = None
        for model in self.candidates:
            try:
                extra_body: Dict[str, Any] = {}
                if "nemotron" in model:
                    extra_body["reasoning"] = {"effort": "none"}

                response = self.client.chat.completions.create(
                    model=model,
                    messages=[{"role": "user", "content": prompt}],
                    temperature=self.temperature,
                    max_tokens=self.max_tokens,
                    extra_body=extra_body if extra_body else None,
                )
                content = response.choices[0].message.content or ""
                if content.strip():
                    return content
            except Exception as e:
                last_error = e
                # Fallback to next candidate free model
                continue

        if last_error:
            raise RuntimeError(f"OpenRouter free models failed across all candidates: {last_error}")
        return ""

    async def a_generate(self, prompt: str) -> str:
        """Asynchronous execution fallback to synchronous client call."""
        return self.generate(prompt)

    def get_model_name(self) -> str:
        return self.model_name

