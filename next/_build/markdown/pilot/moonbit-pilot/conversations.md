# Conversations

## Background

If you encounter particularly good conversations (such as those that solved big problems for you, or when MoonBit Pilot performed exceptionally well and you want to share), or if they don't meet expectations and you want to analyze why they weren't good afterward, then conversation management and export become very useful. Let's see how to use them specifically.

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


Command executed successfully.
=== STDOUT ===
hello

=== STDERR ===

...
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
    ....
  ],
  "name": "Session 7/8/2025, 2:47:46 PM",
  "updated_at": 1751957305413
}
```

## Use Cases

Conversation export is useful for:

- **Documentation**: Save successful problem-solving sessions for future reference
- **Sharing**: Share impressive MoonBit Pilot interactions with your team
- **Analysis**: Review conversations that didn't meet expectations to understand what went wrong
- **Training**: Use successful patterns to improve future interactions
- **Debugging**: Export detailed logs when reporting issues or seeking support
