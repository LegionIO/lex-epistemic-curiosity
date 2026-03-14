# frozen_string_literal: true

module Legion
  module Extensions
    module EpistemicCuriosity
      module Helpers
        class KnowledgeGap
          attr_reader :id, :question, :domain, :gap_type, :explorations, :created_at
          attr_accessor :urgency, :satisfaction, :resolved_at

          def initialize(id:, question:, domain:, gap_type:, urgency: Constants::DEFAULT_URGENCY)
            @id           = id
            @question     = question
            @domain       = domain
            @gap_type     = gap_type
            @urgency      = urgency.clamp(0.0, 1.0)
            @satisfaction = 0.0
            @explorations = 0
            @created_at   = Time.now.utc
            @resolved_at  = nil
          end

          def explore!
            @explorations += 1
            @urgency = (@urgency + Constants::URGENCY_BOOST).clamp(0.0, 1.0)
            self
          end

          def satisfy!(amount: 0.3)
            @satisfaction = (@satisfaction + amount).clamp(0.0, 1.0)
            self
          end

          def resolved?
            @satisfaction >= Constants::SATISFACTION_THRESHOLD
          end

          def urgency_label
            Constants::URGENCY_LABELS.find { |entry| entry[:range].cover?(@urgency) }&.fetch(:label, :mild) || :mild
          end

          def decay!
            @urgency = (@urgency - Constants::URGENCY_DECAY).clamp(0.0, 1.0)
            self
          end

          def to_h
            {
              id:            @id,
              question:      @question,
              domain:        @domain,
              gap_type:      @gap_type,
              urgency:       @urgency.round(4),
              urgency_label: urgency_label,
              satisfaction:  @satisfaction.round(4),
              explorations:  @explorations,
              resolved:      resolved?,
              created_at:    @created_at,
              resolved_at:   @resolved_at
            }
          end
        end
      end
    end
  end
end
