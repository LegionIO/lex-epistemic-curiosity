# lex-epistemic-curiosity

Epistemic curiosity modeling for the LegionIO brain-modeled cognitive architecture.

## What It Does

Models the drive to reduce knowledge uncertainty. Detects specific gaps in the agent's understanding, generates targeted questions to fill them, and tracks information gain when gaps are resolved. Maintains an active inquiry agenda prioritized by urgency. Measures overall curiosity level as a function of active unresolved gaps.

Based on Loewenstein's information gap theory of curiosity.

## Usage

```ruby
client = Legion::Extensions::EpistemicCuriosity::Client.new

# Register a knowledge gap
client.detect_gap(
  domain: :architecture,
  topic: 'distributed locking mechanisms',
  gap_type: :procedural,
  urgency: 0.8
)
# => { success: true, gap_id: "...", urgency_label: :high, inquiry_triggered: true }

# Generate a focused inquiry for a gap
client.generate_inquiry(gap_id: '...')
# => { success: true, inquiry_id: "...", question: "How does distributed locking work?", priority: 0.8 }

# Mark a gap resolved with new information
client.resolve_gap(
  gap_id: '...',
  information: 'Redis SETNX pattern for distributed locking',
  confidence: 0.9
)
# => { success: true, resolved: true, information_gain: 0.72, gain_label: :significant }

# View active inquiry agenda
client.active_inquiries
# => { inquiries: [...sorted by priority], count: 3 }

# Most urgent unresolved gaps
client.priority_gaps(limit: 5)

# Overall curiosity level
client.curiosity_level
# => { curiosity_score: 0.45, active_gap_count: 4, urgency_distribution: { high: 2, moderate: 2 } }

# Periodic maintenance
client.update_epistemic_curiosity
```

## Gap Types

| Type | Example Question Generated |
|---|---|
| `:factual` | "What is X?" |
| `:causal` | "Why does X occur?" |
| `:procedural` | "How does X work?" |
| `:conceptual` | "What does X mean?" |
| `:predictive` | "What will happen with X?" |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
