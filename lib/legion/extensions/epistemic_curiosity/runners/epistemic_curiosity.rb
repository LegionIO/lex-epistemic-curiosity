# frozen_string_literal: true

module Legion
  module Extensions
    module EpistemicCuriosity
      module Runners
        module EpistemicCuriosity
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def create_gap(question:, domain:, gap_type: :factual, urgency: Helpers::Constants::DEFAULT_URGENCY, **)
            result = engine.create_gap(question: question, domain: domain, gap_type: gap_type, urgency: urgency)
            if result[:created]
              Legion::Logging.info "[epistemic_curiosity] gap created: id=#{result[:gap][:id]} domain=#{domain} type=#{gap_type}"
            else
              Legion::Logging.debug "[epistemic_curiosity] gap not created: reason=#{result[:reason]}"
            end
            result
          end

          def explore_gap(gap_id:, **)
            result = engine.explore_gap(gap_id: gap_id)
            if result[:found]
              gap = result[:gap]
              Legion::Logging.debug "[epistemic_curiosity] explore: id=#{gap_id} explorations=#{gap[:explorations]} urgency=#{gap[:urgency]}"
            else
              Legion::Logging.debug "[epistemic_curiosity] explore: id=#{gap_id} not found"
            end
            result
          end

          def satisfy_gap(gap_id:, amount: 0.3, **)
            result = engine.satisfy_gap(gap_id: gap_id, amount: amount)
            if result[:found]
              gap = result[:gap]
              Legion::Logging.debug "[epistemic_curiosity] satisfy: id=#{gap_id} satisfaction=#{gap[:satisfaction]} resolved=#{gap[:resolved]}"
            else
              Legion::Logging.debug "[epistemic_curiosity] satisfy: id=#{gap_id} not found"
            end
            result
          end

          def resolve_gap(gap_id:, **)
            result = engine.resolve_gap(gap_id: gap_id)
            if result[:found]
              Legion::Logging.info "[epistemic_curiosity] resolved: id=#{gap_id}"
            else
              Legion::Logging.debug "[epistemic_curiosity] resolve: id=#{gap_id} not found"
            end
            result
          end

          def most_urgent_gaps(limit: 5, **)
            gaps = engine.most_urgent(limit: limit)
            Legion::Logging.debug "[epistemic_curiosity] most_urgent: limit=#{limit} returned=#{gaps.size}"
            { gaps: gaps.map(&:to_h), count: gaps.size }
          end

          def gaps_by_domain(domain:, **)
            gaps = engine.by_domain(domain)
            Legion::Logging.debug "[epistemic_curiosity] by_domain: domain=#{domain} count=#{gaps.size}"
            { gaps: gaps.map(&:to_h), count: gaps.size, domain: domain }
          end

          def gaps_by_type(gap_type:, **)
            gaps = engine.by_type(gap_type)
            Legion::Logging.debug "[epistemic_curiosity] by_type: gap_type=#{gap_type} count=#{gaps.size}"
            { gaps: gaps.map(&:to_h), count: gaps.size, gap_type: gap_type }
          end

          def decay_gaps(**)
            count = engine.decay_all
            Legion::Logging.debug "[epistemic_curiosity] decay cycle: gaps_updated=#{count}"
            { decayed: count }
          end

          def curiosity_report(**)
            report = engine.curiosity_report
            Legion::Logging.debug "[epistemic_curiosity] report: open=#{report[:open_gaps]} debt=#{report[:information_debt]}"
            report
          end

          def curiosity_status(**)
            {
              total_gaps:             engine.open_gaps.size + engine.resolved_gaps.size,
              open_gaps:              engine.open_gaps.size,
              resolved_gaps:          engine.resolved_gaps.size,
              information_debt:       engine.information_debt,
              exploration_efficiency: engine.exploration_efficiency
            }
          end

          private

          def engine
            @engine ||= Helpers::CuriosityEngine.new
          end
        end
      end
    end
  end
end
