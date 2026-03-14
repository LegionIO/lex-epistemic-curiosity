# frozen_string_literal: true

module Legion
  module Extensions
    module EpistemicCuriosity
      module Helpers
        module Constants
          MAX_GAPS             = 300
          DEFAULT_URGENCY      = 0.5
          URGENCY_BOOST        = 0.08
          URGENCY_DECAY        = 0.03
          SATISFACTION_THRESHOLD = 0.8

          GAP_TYPES = %i[factual conceptual procedural causal relational].freeze

          URGENCY_LABELS = [
            { range: (0.8..1.0), label: :burning },
            { range: (0.6...0.8), label: :intense   },
            { range: (0.4...0.6), label: :moderate  },
            { range: (0.2...0.4), label: :mild      },
            { range: (0.0...0.2), label: :satisfied }
          ].freeze
        end
      end
    end
  end
end
