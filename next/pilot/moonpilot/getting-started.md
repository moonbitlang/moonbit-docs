# Getting Started with MoonPilot

## MoonPilot

![Image: MoonPilot interface overview](/imgs/pilot/pilot-01.png)

Unleash MoonBit language's raw power directly in your terminal. Search million-line codebases instantly. Turn hours-long workflows into a single command. Your tools. Your workflow. Your codebase, evolving at thought speed.

## Model Configuration

Before using MoonPilot, you need to configure at least one model by creating a configuration file at `~/.moonpilot/models/models.json`:

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
    "description": "",
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

### Configuration Fields Explanation

- **name**: A unique identifier for the model (used for reference)
- **description**: Human-readable description of the model
- **model_name**: The actual model identifier used by the API provider
- **model_type**: Type of API interface (currently supports "saas/openai")
- **base_url**: API endpoint URL for the model provider
- **is_reasoning**: Whether this is a reasoning model (affects token counting)
- **input_price**: Cost per million input tokens (in USD)
- **output_price**: Cost per million output tokens (in USD)
- **max_output_tokens**: Maximum number of tokens the model can output
- **context_window**: Total context window size in tokens
- **api_key**: Your API key for this provider

### About the Example Models

The configuration above includes two popular models:

- **Claude Sonnet 4** (`sonnet4`): Anthropic's latest high-performance model via OpenRouter
  - High context window (200k tokens) for complex tasks
  - Premium pricing but excellent quality
  
- **Kimi K2** (`k2`): Moonshot's cost-effective model
  - Good performance with lower pricing
  - 120k token context window
  - Great for everyday development tasks

### Getting API Keys

To use these models, you'll need to obtain API keys:

- **OpenRouter** (for Claude Sonnet 4): Visit [openrouter.ai](https://openrouter.ai) to create an account and get your API key
- **Moonshot** (for Kimi K2): Visit [moonshot.cn](https://platform.moonshot.cn) to register and obtain your API key

Replace `"your-api-key-here"` with your actual API keys in the configuration.


## Setup

Install Node.js [v22.16.0](https://nodejs.org/en/download) then run:

```bash
moon pilot
```


## Usage

MoonPilot will automatically use the first model in your configuration file (in this case, "sonnet4"). You can configure multiple models and they can be specified by `--model` parameter when you start MoonPilot.

## Interactive Mode

Start interactive mode using the first model specified in preview section.

```bash
moon pilot
```


Or specify a particular model:

```bash
moon pilot --model k2
```


### Interactive Commands

Once in interactive mode, you can input your requirements normally and MoonPilot will respond and execute tasks for you.

```bash
act ▶ what does this project do?
```

### Exiting Interactive Mode

- Use `:exit` or `Ctrl+D` to exit the application
- Use `Ctrl+C` to stop the current request and clear the current input



## Print/Non-Interactive Mode

You can execute one-time commands through the `-p` flag. Non-interactive mode supports piping:

```bash
echo "What does this project do" | moon pilot -p
```
This command will automatically exit after completion, making it perfect for programmatic calls (through subprocess forking in programming languages or shell script invocation).

You can also use it with `cat`:

```bash
cat prompt.md | moon pilot -p
```

Additionally, non-interactive mode also has session concepts. The previous commands each create a new session, which can be simply understood as stateless.

You can view recently executed non-interactive commands through `conversations`:

```bash
moon pilot conversations
```

```bash
1. 0ada20c9
   Name: Session 7/18/2025, 2:30:40 PM
   Description: Interactive conversation
   Messages: 0
   Created: 7/18/2025, 2:30:40 PM
   Updated: 7/18/2025, 2:30:40 PM

2. e1a5b071
   Name: Session 7/17/2025, 11:55:38 AM
   Description: Interactive conversation
   Messages: 18
   Created: 7/17/2025, 11:55:38 AM
   Updated: 7/17/2025, 11:56:32 AM
```


You can view details through session ID:

```bash
moon pilot conversation 0ada20c9
```

or you can export the conversation to makrdown file:

```bash
moon pilot conversation 0ada20c9 --output conversation.md
```

If you want to continue from the last command execution, allowing this modification to have the context from the previous time, you can use `--continue` to continue the last session. This way, both commands will share the same conversation list:

```bash
echo "What did I ask you before?" | moon pilot -p --continue
```

This allows you to complete conversations through multiple `moon pilot` calls. This means any third-party application can easily integrate with `moon pilot` through simple command-line calls. In the future, we can also provide SDKs for various languages, making it convenient for other languages to use `moon pilot` to create interactive interfaces and implement package migration work.

Of course, you can also resume to a specific session using the `--resume` parameter, which will switch to that session:

```bash
echo "What did I ask you before?" | moon pilot -p --resume ed19c993
```

This provides excellent controllability. 