# frozen_string_literal: true

module Legion
  module Extensions
    module EpistemicCuriosity
      module Helpers
        class CuriosityEngine
          def initialize
            @gaps    = {}
            @counter = 0
          end

          def create_gap(question:, domain:, gap_type: :factual, urgency: Constants::DEFAULT_URGENCY)
            prune_resolved if @gaps.size >= Constants::MAX_GAPS
            return { created: false, reason: :at_capacity } if @gaps.size >= Constants::MAX_GAPS

            gap_type = :factual unless Constants::GAP_TYPES.include?(gap_type)
            id       = next_id
            gap      = KnowledgeGap.new(id: id, question: question, domain: domain, gap_type: gap_type, urgency: urgency)
            @gaps[id] = gap
            { created: true, gap: gap.to_h }
          end

          def explore_gap(gap_id:)
            gap = @gaps[gap_id]
            return { found: false, gap_id: gap_id } unless gap

            gap.explore!
            { found: true, gap: gap.to_h }
          end

          def satisfy_gap(gap_id:, amount: 0.3)
            gap = @gaps[gap_id]
            return { found: false, gap_id: gap_id } unless gap

            gap.satisfy!(amount: amount)
            { found: true, gap: gap.to_h }
          end

          def resolve_gap(gap_id:)
            gap = @gaps[gap_id]
            return { found: false, gap_id: gap_id } unless gap

            gap.satisfaction = 1.0
            gap.resolved_at  = Time.now.utc
            { found: true, resolved: true, gap: gap.to_h }
          end

          def open_gaps
            @gaps.values.reject(&:resolved?)
          end

          def resolved_gaps
            @gaps.values.select(&:resolved?)
          end

          def most_urgent(limit: 5)
            open_gaps.sort_by { |g| -g.urgency }.first(limit)
          end

          def by_domain(domain)
            @gaps.values.select { |g| g.domain == domain }
          end

          def by_type(gap_type)
            @gaps.values.select { |g| g.gap_type == gap_type }
          end

          def information_debt
            open_gaps.sum(&:urgency).round(4)
          end

          def exploration_efficiency
            total = @gaps.size
            return 0.0 if total.zero?

            (resolved_gaps.size.to_f / total).round(4)
          end

          def decay_all
            @gaps.each_value(&:decay!)
            @gaps.size
          end

          def prune_resolved
            @gaps.delete_if { |_id, gap| gap.resolved? }
          end

          def curiosity_report
            {
              total_gaps:             @gaps.size,
              open_gaps:              open_gaps.size,
              resolved_gaps:          resolved_gaps.size,
              information_debt:       information_debt,
              exploration_efficiency: exploration_efficiency,
              most_urgent:            most_urgent(limit: 3).map(&:to_h)
            }
          end

          def to_h
            {
              gaps:                   @gaps.transform_values(&:to_h),
              information_debt:       information_debt,
              exploration_efficiency: exploration_efficiency
            }
          end

          private

          def next_id
            @counter += 1
            :"gap_#{@counter}"
          end
        end
      end
    end
  end
end
