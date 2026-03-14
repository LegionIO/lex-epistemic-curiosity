# frozen_string_literal: true

RSpec.describe Legion::Extensions::EpistemicCuriosity::Helpers::CuriosityEngine do
  subject(:engine) { described_class.new }

  let(:basic_gap_args) { { question: 'What is X?', domain: :science, gap_type: :factual } }

  describe '#create_gap' do
    it 'creates a gap and returns created: true' do
      result = engine.create_gap(**basic_gap_args)
      expect(result[:created]).to be true
    end

    it 'returns the gap hash' do
      result = engine.create_gap(**basic_gap_args)
      expect(result[:gap]).to be_a(Hash)
      expect(result[:gap][:question]).to eq('What is X?')
    end

    it 'assigns incremental ids' do
      r1 = engine.create_gap(**basic_gap_args)
      r2 = engine.create_gap(**basic_gap_args)
      expect(r1[:gap][:id]).not_to eq(r2[:gap][:id])
    end

    it 'defaults gap_type to :factual for unknown type' do
      result = engine.create_gap(question: 'q', domain: :d, gap_type: :unknown_type)
      expect(result[:gap][:gap_type]).to eq(:factual)
    end

    it 'accepts custom urgency' do
      result = engine.create_gap(**basic_gap_args, urgency: 0.9)
      expect(result[:gap][:urgency]).to eq(0.9)
    end
  end

  describe '#explore_gap' do
    it 'returns found: false for unknown gap' do
      result = engine.explore_gap(gap_id: :nonexistent)
      expect(result[:found]).to be false
    end

    it 'increments explorations' do
      id = engine.create_gap(**basic_gap_args)[:gap][:id]
      result = engine.explore_gap(gap_id: id)
      expect(result[:gap][:explorations]).to eq(1)
    end

    it 'boosts urgency' do
      id    = engine.create_gap(**basic_gap_args, urgency: 0.5)[:gap][:id]
      after = engine.explore_gap(gap_id: id)[:gap][:urgency]
      expect(after).to be > 0.5
    end
  end

  describe '#satisfy_gap' do
    it 'returns found: false for unknown gap' do
      expect(engine.satisfy_gap(gap_id: :nope)[:found]).to be false
    end

    it 'increases satisfaction' do
      id = engine.create_gap(**basic_gap_args)[:gap][:id]
      engine.satisfy_gap(gap_id: id, amount: 0.4)
      result = engine.satisfy_gap(gap_id: id, amount: 0.4)
      expect(result[:gap][:satisfaction]).to be > 0.4
    end
  end

  describe '#resolve_gap' do
    it 'returns found: false for unknown gap' do
      expect(engine.resolve_gap(gap_id: :nope)[:found]).to be false
    end

    it 'sets satisfaction to 1.0' do
      id = engine.create_gap(**basic_gap_args)[:gap][:id]
      engine.resolve_gap(gap_id: id)
      gap = engine.resolved_gaps.first
      expect(gap.satisfaction).to eq(1.0)
    end

    it 'moves gap to resolved_gaps' do
      id = engine.create_gap(**basic_gap_args)[:gap][:id]
      engine.resolve_gap(gap_id: id)
      expect(engine.resolved_gaps.size).to eq(1)
    end
  end

  describe '#open_gaps / #resolved_gaps' do
    before do
      engine.create_gap(**basic_gap_args)
      id2 = engine.create_gap(**basic_gap_args)[:gap][:id]
      engine.resolve_gap(gap_id: id2)
    end

    it 'open_gaps returns unresolved gaps' do
      expect(engine.open_gaps.size).to eq(1)
    end

    it 'resolved_gaps returns resolved gaps' do
      expect(engine.resolved_gaps.size).to eq(1)
    end
  end

  describe '#most_urgent' do
    it 'returns gaps sorted by urgency descending' do
      engine.create_gap(**basic_gap_args, urgency: 0.3)
      engine.create_gap(**basic_gap_args, urgency: 0.9)
      engine.create_gap(**basic_gap_args, urgency: 0.6)
      urgent = engine.most_urgent(limit: 2)
      expect(urgent.first.urgency).to be >= urgent.last.urgency
    end

    it 'respects the limit' do
      5.times { engine.create_gap(**basic_gap_args) }
      expect(engine.most_urgent(limit: 2).size).to eq(2)
    end
  end

  describe '#by_domain' do
    it 'filters by domain' do
      engine.create_gap(question: 'q1', domain: :science, gap_type: :factual)
      engine.create_gap(question: 'q2', domain: :history, gap_type: :factual)
      expect(engine.by_domain(:science).size).to eq(1)
    end
  end

  describe '#by_type' do
    it 'filters by gap_type' do
      engine.create_gap(question: 'q1', domain: :d, gap_type: :causal)
      engine.create_gap(question: 'q2', domain: :d, gap_type: :factual)
      expect(engine.by_type(:causal).size).to eq(1)
    end
  end

  describe '#information_debt' do
    it 'sums urgency of open gaps' do
      engine.create_gap(**basic_gap_args, urgency: 0.4)
      engine.create_gap(**basic_gap_args, urgency: 0.6)
      expect(engine.information_debt).to be_within(0.01).of(1.0)
    end

    it 'excludes resolved gaps' do
      id = engine.create_gap(**basic_gap_args, urgency: 0.8)[:gap][:id]
      engine.resolve_gap(gap_id: id)
      expect(engine.information_debt).to eq(0.0)
    end
  end

  describe '#exploration_efficiency' do
    it 'returns 0.0 with no gaps' do
      expect(engine.exploration_efficiency).to eq(0.0)
    end

    it 'returns 1.0 when all gaps resolved' do
      id = engine.create_gap(**basic_gap_args)[:gap][:id]
      engine.resolve_gap(gap_id: id)
      expect(engine.exploration_efficiency).to eq(1.0)
    end

    it 'returns 0.5 when half resolved' do
      engine.create_gap(**basic_gap_args)
      id2 = engine.create_gap(**basic_gap_args)[:gap][:id]
      engine.resolve_gap(gap_id: id2)
      expect(engine.exploration_efficiency).to be_within(0.01).of(0.5)
    end
  end

  describe '#decay_all' do
    it 'returns the number of gaps affected' do
      2.times { engine.create_gap(**basic_gap_args) }
      expect(engine.decay_all).to eq(2)
    end

    it 'reduces urgency of open gaps' do
      id     = engine.create_gap(**basic_gap_args, urgency: 0.5)[:gap][:id]
      before = engine.open_gaps.find { |g| g.id == id }.urgency
      engine.decay_all
      after = engine.open_gaps.find { |g| g.id == id }.urgency
      expect(after).to be < before
    end
  end

  describe '#prune_resolved' do
    it 'removes resolved gaps' do
      id = engine.create_gap(**basic_gap_args)[:gap][:id]
      engine.resolve_gap(gap_id: id)
      engine.prune_resolved
      expect(engine.resolved_gaps.size).to eq(0)
    end

    it 'keeps open gaps' do
      engine.create_gap(**basic_gap_args)
      id2 = engine.create_gap(**basic_gap_args)[:gap][:id]
      engine.resolve_gap(gap_id: id2)
      engine.prune_resolved
      expect(engine.open_gaps.size).to eq(1)
    end
  end

  describe '#curiosity_report' do
    it 'returns expected keys' do
      report = engine.curiosity_report
      expect(report.keys).to include(:total_gaps, :open_gaps, :resolved_gaps, :information_debt, :exploration_efficiency, :most_urgent)
    end

    it 'most_urgent is an array of hashes' do
      engine.create_gap(**basic_gap_args)
      expect(engine.curiosity_report[:most_urgent]).to be_an(Array)
      expect(engine.curiosity_report[:most_urgent].first).to be_a(Hash)
    end
  end

  describe '#to_h' do
    it 'returns a hash with gaps key' do
      engine.create_gap(**basic_gap_args)
      result = engine.to_h
      expect(result).to have_key(:gaps)
      expect(result[:gaps]).to be_a(Hash)
    end

    it 'includes information_debt' do
      expect(engine.to_h).to have_key(:information_debt)
    end

    it 'includes exploration_efficiency' do
      expect(engine.to_h).to have_key(:exploration_efficiency)
    end
  end
end
