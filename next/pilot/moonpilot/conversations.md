# Conversation Management

## Background

If you encounter particularly good conversations (such as those that solved big problems for you, or when MoonPilot performed exceptionally well and you want to share), or if they don't meet expectations and you want to analyze why they weren't good afterward, then conversation management and export become very useful. Let's see how to use them specifically.

## List All Conversations in Current Project

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

## View Conversation Details

```bash
moon pilot conversation 2b2fda32
```


## Export to Markdown Format

```bash
moon pilot conversation 2b2fda32 --output conversation.md
```

Opening the file shows the following result:

```markdown
# Conversation: 2b2fda32-f045-43e9-a51f-37d3ec93c21c

**Name:** Session 7/8/2025, 2:47:46 PM
**Description:** Interactive conversation
**Created:** 7/8/2025, 2:47:46 PM
**Updated:** 7/8/2025, 2:48:25 PM
**Messages:** 6

## 👤 User

### Content

Run echo hello until all errors are fixed

**Timestamp:** 7/8/2025, 2:48:01 PM

---

## 🤖 Assistant

### Content

I will run the `echo hello` command for you. This is a simple command that should not produce any errors.

**🔧 Tool Call:** Execute command (execute_command)

**Parameters:**
- **command:** echo hello
- **timeout:** 5000

**Timestamp:** 7/8/2025, 2:48:06 PM

---

## 🔧 Tool

### Content

**🔧 Tool:** Execute command (execute_command)

**Result:**

```
Command executed successfully.
=== STDOUT ===
hello

=== STDERR ===

```

**Call ID:** toolu_vr...

**Timestamp:** 7/8/2025, 2:48:06 PM

---

## 🤖 Assistant

### Content

The command `echo hello` has been executed successfully, outputting "hello" with no errors. The command has completed and no error fixes are needed.

**🔧 Tool Call:** Complete task (attempt_completion)

**Parameters:**
- **result:** The command `echo hello` has been executed successfully with output "hello". No errors were found, so no fixes are needed. The command has completed normally.

**Timestamp:** 7/8/2025, 2:48:12 PM

---

## 🔧 Tool

### Content

**🔧 Tool:** Complete task (attempt_completion)

**Result:**

```
The user is satisfied with the result.
```

**Call ID:** toolu_vr...

**Timestamp:** 7/8/2025, 2:48:25 PM

---

## 🤖 Assistant

### Content

I am pleased you are satisfied with the result. Do you have a new task for me?

**Timestamp:** 7/8/2025, 2:48:25 PM
```

## Export to JSON Format

```bash
moon pilot conversation 2b2fda32 --output conversation.json
```

The output result is as follows:

```json
{
  "created_at": 1751957266580,
  "description": "Interactive conversation",
  "id": "2b2fda32-f045-43e9-a51f-37d3ec93c21c",
  "messages": [
    {
      "content": "{\"content\":\"Run echo hello until all errors are fixed\",\"role\":\"user\"}",
      "id": "79a14c23-343e-457d-b0bb-5a069c36a7a0",
      "role": "user",
      "timestamp": 1751957281111
    },
    {
      "content": "{\"content\":\"I will run the `echo hello` command for you. This is a simple command that should not produce any errors.\",\"role\":\"assistant\",\"tool_calls\":[{\"id\":\"toolu_vrtx_019Fj5tSLLHHZSqY7nhB4whK\",\"index\":0,\"type\":\"function\",\"function\":{\"name\":\"execute_command\",\"arguments\":\"{\\\"command\\\": \\\"echo hello\\\", \\\"timeout\\\": 5000}\"}}]}",
      "id": "79a684eb-a60b-4b0a-8664-318592861bb8",
      "role": "assistant",
      "timestamp": 1751957286228
    },
    {
      "content": "{\"content\":\"Command executed successfully.\\n=== STDOUT ===\\nhello\\n\\n=== STDERR ===\\n\",\"name\":\"execute_command\",\"role\":\"tool\",\"tool_call_id\":\"toolu_vrtx_019Fj5tSLLHHZSqY7nhB4whK\"}",
      "id": "0bfbeff8-b108-4943-a6c2-55a8458c893f",
      "role": "tool",
      "timestamp": 1751957286343
    },
    {
      "content": "{\"content\":\"The command `echo hello` has been executed successfully, outputting \\\"hello\\\" with no errors. The command has completed and no error fixes are needed.\",\"role\":\"assistant\",\"tool_calls\":[{\"id\":\"toolu_vrtx_012ZEdGdGRChxeM6B4nTq3kK\",\"index\":0,\"type\":\"function\",\"function\":{\"name\":\"attempt_completion\",\"arguments\":\"{\\\"result\\\": \\\"The command `echo hello` has been executed successfully with output \\\\\\\"hello\\\\\\\". No errors were found, so no fixes are needed. The command has completed normally.\\\"}\"}}]}",
      "id": "cd51173e-dcc6-48bf-9f46-d629c814cf18",
      "role": "assistant",
      "timestamp": 1751957292182
    },
    {
      "content": "{\"content\":\"The user is satisfied with the result.\",\"name\":\"attempt_completion\",\"role\":\"tool\",\"tool_call_id\":\"toolu_vrtx_012ZEdGdGRChxeM6B4nTq3kK\"}",
      "id": "b3c884e2-574c-4930-aa0c-f0b85cd1bb5f",
      "role": "tool",
      "timestamp": 1751957305412
    },
    {
      "content": "{\"content\":\"I am pleased you are satisfied with the result. Do you have a new task for me?\",\"role\":\"assistant\",\"tool_calls\":[]}",
      "id": "ff74b13f-6c2a-4fb5-a0ee-bda245105885",
      "role": "assistant",
      "timestamp": 1751957305413
    }
  ],
  "name": "Session 7/8/2025, 2:47:46 PM",
  "updated_at": 1751957305413
}
```

## Use Cases

Conversation export is useful for:

- **Documentation**: Save successful problem-solving sessions for future reference
- **Sharing**: Share impressive MoonPilot interactions with your team
- **Analysis**: Review conversations that didn't meet expectations to understand what went wrong
- **Training**: Use successful patterns to improve future interactions
- **Debugging**: Export detailed logs when reporting issues or seeking support 