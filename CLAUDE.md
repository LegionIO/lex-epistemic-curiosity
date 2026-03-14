# lex-epistemic-curiosity

**Level 3 Documentation** — Parent: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`

## Purpose

Epistemic curiosity modeling for the LegionIO cognitive architecture. Models curiosity specifically about knowledge gaps — the drive to reduce uncertainty through information seeking. Distinct from lex-curiosity (which handles broad wonder/exploration), this extension focuses on the epistemic dimension: detecting gaps in the agent's knowledge, generating specific questions to fill them, tracking information gain from resolved gaps, and managing an active inquiry agenda.

Based on Loewenstein's information gap theory of curiosity.

## Gem Info

- **Gem name**: `lex-epistemic-curiosity`
- **Version**: `0.1.0`
- **Namespace**: `Legion::Extensions::EpistemicCuriosity`
- **Location**: `extensions-agentic/lex-epistemic-curiosity/`

## File Structure

```
lib/legion/extensions/epistemic_curiosity/
  epistemic_curiosity.rb        # Top-level requires
  version.rb                    # VERSION = '0.1.0'
  client.rb                     # Client class
  helpers/
    constants.rb                # GAP_TYPES, INQUIRY_STATES, URGENCY_LABELS, thresholds
    knowledge_gap.rb            # KnowledgeGap value object
    inquiry.rb                  # Inquiry value object (question + status)
    epistemic_engine.rb         # Engine: gap detection, inquiry management, information gain
  runners/
    epistemic_curiosity.rb      # Runner module: all public methods
```

## Key Constants

| Constant | Value | Purpose |
|---|---|---|
| `GAP_TYPES` | `[:factual, :causal, :procedural, :conceptual, :predictive]` | Categories of knowledge gaps |
| `INQUIRY_STATES` | `[:open, :active, :resolved, :abandoned]` | Inquiry lifecycle states |
| `GAP_URGENCY_THRESHOLD` | 0.6 | Urgency above which a gap triggers active inquiry |
| `INFORMATION_GAIN_DECAY` | 0.02 | Information gain from resolved gaps decays per cycle |
| `MAX_GAPS` | 100 | Active knowledge gap cap |
| `MAX_INQUIRIES` | 200 | Inquiry history cap |
| `CURIOSITY_ACTIVATION_THRESHOLD` | 0.3 | Minimum curiosity level to generate new inquiries |
| `URGENCY_LABELS` | range hash | `critical / high / moderate / low / trivial` |
| `INFORMATION_GAIN_LABELS` | range hash | `transformative / significant / moderate / minimal / negligible` |

## Runners

All methods in `Legion::Extensions::EpistemicCuriosity::Runners::EpistemicCuriosity`.

| Method | Key Args | Returns |
|---|---|---|
| `detect_gap` | `domain:, topic:, gap_type:, urgency: 0.5` | `{ success:, gap_id:, domain:, urgency_label:, inquiry_triggered: }` |
| `generate_inquiry` | `gap_id:` | `{ success:, inquiry_id:, question:, gap_id:, priority: }` |
| `resolve_gap` | `gap_id:, information:, confidence: 0.8` | `{ success:, gap_id:, resolved:, information_gain:, gain_label: }` |
| `abandon_inquiry` | `inquiry_id:, reason: nil` | `{ success:, inquiry_id:, abandoned: }` |
| `active_inquiries` | — | `{ success:, inquiries:, count: }` |
| `priority_gaps` | `limit: 5` | `{ success:, gaps:, count: }` (sorted by urgency) |
| `curiosity_level` | — | `{ success:, curiosity_score:, active_gap_count:, urgency_distribution: }` |
| `information_gain_summary` | — | `{ success:, total_gain:, gain_label:, resolved_count:, gain_by_type: }` |
| `update_epistemic_curiosity` | — | `{ success:, gaps_decayed:, inquiries_pruned: }` |
| `epistemic_curiosity_stats` | — | Full stats hash |

## Helpers

### `KnowledgeGap`
Value object. Attributes: `id`, `domain`, `topic`, `gap_type`, `urgency` (float 0–1), `created_at`, `resolved_at`, `resolved`. `urgency_label`, `to_h`.

### `Inquiry`
Value object. Attributes: `id`, `gap_id`, `question` (string), `state`, `priority`, `created_at`, `resolved_at`, `information_gained`. Key methods: `activate!`, `resolve!(information:, gain:)`, `abandon!(reason:)`, `to_h`.

### `EpistemicEngine`
Central store: `@gaps` (hash by id), `@inquiries` (hash by id), `@total_information_gain` (float). Key methods:
- `detect_gap(domain:, topic:, gap_type:, urgency:)`: creates KnowledgeGap, auto-generates Inquiry if urgency >= `GAP_URGENCY_THRESHOLD`
- `generate_inquiry(gap_id:)`: creates Inquiry for gap, generates question from topic + gap_type template
- `resolve_gap(gap_id:, information:, confidence:)`: marks gap resolved, computes information gain from urgency * confidence, updates `@total_information_gain`
- `curiosity_score`: weighted sum of active gap urgencies / MAX_GAPS
- `decay_gains`: reduces historical information gains by `INFORMATION_GAIN_DECAY` per cycle

## Integration Points

- `detect_gap` called from lex-tick's `working_memory_integration` phase when prediction fails (gap = failed prediction)
- `priority_gaps` feeds lex-curiosity's wonder agenda (epistemic gaps become high-priority wonders)
- `curiosity_level[:curiosity_score]` feeds lex-emotion arousal as positive activating signal
- `information_gain_summary` contributes to lex-governance's oversight metrics
- `update_epistemic_curiosity` maps to lex-tick's periodic maintenance cycle

## Development Notes

- This extension is narrower than lex-curiosity: only epistemic (knowledge) gaps, not exploratory wonder
- Question generation is template-based per `GAP_TYPE`: factual = "What is X?", causal = "Why does X occur?", etc.
- Information gain is computed, not observed — it is estimated from urgency * confidence at resolution time
- Urgency does not decay on active gaps — gaps stay urgent until resolved or abandoned
- `CURIOSITY_ACTIVATION_THRESHOLD` gates inquiry generation but NOT gap detection — gaps are always recorded
