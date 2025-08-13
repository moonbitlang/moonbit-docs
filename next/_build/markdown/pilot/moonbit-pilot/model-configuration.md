# Model Configuration

## Model Management

Before using MoonBit Pilot, you need to configure at least one model by creating a configuration file at `~/.moonagent/models/models.json`:

```json
[
  {
    "name": "sonnet4",
    "description": "Claude Sonnet model for general tasks",
    "model_name": "anthropic/claude-sonnet-4",
    "model_type": "saas/openai",
    "base_url": "https://openrouter.ai/api/v1",    
    "is_reasoning": false,
    "input_price": 3.0,
    "output_price": 15.0,    
    "max_output_tokens": 8096,
    "context_window": 200000,
    "api_key": "your-api-key-here"
  },
  {
    "name": "k2",
    "description": "Moonshot Kimi model for cost-effective tasks",
    "model_name": "kimi-k2-0711-preview",
    "model_type": "saas/openai",
    "base_url": "https://api.moonshot.cn/v1",
    "is_reasoning": false,
    "input_price": 0.28,
    "output_price": 2.28,
    "max_output_tokens": 8096,
    "context_window": 120000,    
    "api_key": "your-api-key-here"
  }
]
```

## Configuration Parameters

The following table describes all available configuration parameters:

| Parameter           | Type    | Required   | Description                                                                     |
|---------------------|---------|------------|---------------------------------------------------------------------------------|
| `name`              | String  | Yes        | A unique identifier for the model (used for reference with `--model` parameter) |
| `description`       | String  | No         | Human-readable description of the model                                         |
| `model_name`        | String  | Yes        | The actual model identifier used by the API provider                            |
| `model_type`        | String  | Yes        | Type of API interface (currently supports "saas/openai")                        |
| `base_url`          | String  | Yes        | API endpoint URL for the model provider                                         |
| `is_reasoning`      | Boolean | Yes        | Whether this is a reasoning model (affects token counting)                      |
| `input_price`       | Number  | No         | Cost per million input tokens (in USD)                                          |
| `output_price`      | Number  | No         | Cost per million output tokens (in USD)                                         |
| `max_output_tokens` | Number  | No         | Maximum number of tokens the model can output                                   |
| `context_window`    | Number  | No         | Total context window size in tokens                                             |
| `api_key`           | String  | Yes        | Your API key for this provider                                                  |

## Example Models

The configuration above includes two popular models:

### Claude Sonnet 4 (`sonnet4`)

- **Provider**: Anthropic via OpenRouter
- **Performance**: High-performance model with excellent quality
- **Context Window**: 200,000 tokens for complex tasks
- **Pricing**: Premium pricing but excellent quality
- **Best For**: Complex reasoning, large codebases, high-quality outputs

### Kimi K2 (`k2`)

- **Provider**: Moonshot AI
- **Performance**: Good performance with cost-effective pricing
- **Context Window**: 120,000 tokens
- **Pricing**: Budget-friendly option
- **Best For**: Everyday development tasks, cost-conscious projects

## Supported Models

MoonBit Pilot supports the following models through various API providers:

| Model                 | Provider             | Model Name                    | Base URL                       | Notes                        |
|-----------------------|----------------------|-------------------------------|--------------------------------|------------------------------|
| **Kimi K2**           | Moonshot             | `kimi-k2-0711-preview`        | `https://api.moonshot.cn/v1`   | Cost-effective, 120k context |
| **DeepSeek V3**       | DeepSeek             | `deepseek-chat`               | `https://api.deepseek.com/v1`  | High performance reasoning   |
| **DeepSeek R1**       | DeepSeek             | `deepseek-reasoner`           | `https://api.deepseek.com/v1`  | Advanced reasoning model     |
| **Claude Sonnet 4.0** | Anthropic/OpenRouter | `anthropic/claude-sonnet-4`   | `https://openrouter.ai/api/v1` | Latest high-performance      |
| **Claude Sonnet 3.7** | Anthropic/OpenRouter | `anthropic/claude-3.7-sonnet` | `https://openrouter.ai/api/v1` | Latest high-performance      |
| **Claude Opus 4.0**   | Anthropic/OpenRouter | `anthropic/claude-opus-4`     | `https://openrouter.ai/api/v1` | Premium quality              |
| **Gemini 2.5 Pro**    | Google/OpenRouter    | `google/gemini-2.5-pro`       | `https://openrouter.ai/api/v1` | Google's latest model        |
| **GPT-4.1**           | OpenAI/OpenRouter    | `openai/gpt-4.1`              | `https://openrouter.ai/api/v1` | OpenAI's advanced model      |

### Configuration Examples

Here are configuration examples for some of the supported models:

#### DeepSeek V3

```json
{
  "name": "deepseek-v3",
  "description": "DeepSeek V3 for high performance reasoning",
  "model_name": "deepseek-chat",
  "model_type": "saas/openai",
  "base_url": "https://api.deepseek.com",
  "is_reasoning": false,
  "input_price": 0.25,
  "output_price": 0.85,
  "max_output_tokens": 8000,
  "context_window": 128000,
  "api_key": "your-deepseek-api-key"
}
```

#### Claude Sonnet 3.7

```json
{
  "name": "sonnet-3.7",
  "description": "Claude Sonnet 3.7 for balanced performance",
  "model_name": "anthropic/claude-3.7-sonnet",
  "model_type": "saas/openai",
  "base_url": "https://openrouter.ai/api/v1",
  "is_reasoning": false,
  "input_price": 3.0,
  "output_price": 15.0,
  "max_output_tokens": 8192,
  "context_window": 200000,
  "api_key": "your-openrouter-api-key"
}
```

#### Gemini 2.5 Pro

```json
{
  "name": "gemini-2.5-pro",
  "description": "Google Gemini 2.5 Pro",
  "model_name": "google/gemini-2.5-pro",
  "model_type": "saas/openai",
  "base_url": "https://openrouter.ai/api/v1",
  "is_reasoning": false,
  "input_price": 1.25,
  "output_price": 10,
  "max_output_tokens": 16192,
  "context_window": 1048576,
  "api_key": "your-openrouter-api-key"
}
```

## Getting API Keys

To use these models, you'll need to obtain API keys from the respective providers:

### OpenRouter (for Claude Sonnet 4)

1. Visit [openrouter.ai](https://openrouter.ai)
2. Create an account
3. Navigate to your API keys section
4. Generate a new API key
5. Replace `"your-api-key-here"` in the `sonnet4` configuration

### Moonshot (for Kimi K2)

1. Visit [platform.moonshot.cn](https://platform.moonshot.cn)
2. Register for an account
3. Access your API keys in the dashboard
4. Generate a new API key
5. Replace `"your-api-key-here"` in the `k2` configuration

### DeepSeek (for DeepSeek V3/R1)

1. Visit [platform.deepseek.com](https://platform.deepseek.com)
2. Create an account
3. Navigate to API keys section
4. Generate a new API key
5. Replace `"your-deepseek-api-key"` in your DeepSeek model configuration

## Usage

After configuring your models, you can use them with MoonBit Pilot:

```bash
# Use the first model in your configuration (default)
moon pilot

# Specify a particular model
moon pilot --model k2
moon pilot --model sonnet4
moon pilot --model deepseek-v3
moon pilot --model sonnet-3.5
moon pilot --model gemini-2.5-pro
```

You can add multiple models to the configuration and specify the model name using the `--model` parameter.
