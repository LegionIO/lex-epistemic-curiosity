# frozen_string_literal: true

require 'legion/extensions/epistemic_curiosity/client'

RSpec.describe Legion::Extensions::EpistemicCuriosity::Runners::EpistemicCuriosity do
  let(:client) { Legion::Extensions::EpistemicCuriosity::Client.new }

  let(:gap_args) { { question: 'What causes latency spikes?', domain: :infrastructure, gap_type: :causal } }

  describe '#create_gap' do
    it 'creates a gap with created: true' do
      result = client.create_gap(**gap_args)
      expect(result[:created]).to be true
    end

    it 'returns gap data with question' do
      result = client.create_gap(**gap_args)
      expect(result[:gap][:question]).to eq('What causes latency spikes?')
    end

    it 'uses default urgency when not specified' do
      result = client.create_gap(**gap_args)
      expect(result[:gap][:urgency]).to eq(Legion::Extensions::EpistemicCuriosity::Helpers::Constants::DEFAULT_URGENCY)
    end

    it 'accepts custom urgency' do
      result = client.create_gap(**gap_args, urgency: 0.9)
      expect(result[:gap][:urgency]).to eq(0.9)
    end
  end

  describe '#explore_gap' do
    it 'returns found: false for unknown gap_id' do
      result = client.explore_gap(gap_id: :nonexistent)
      expect(result[:found]).to be false
    end

    it 'increments explorations for known gap' do
      id = client.create_gap(**gap_args)[:gap][:id]
      result = client.explore_gap(gap_id: id)
      expect(result[:gap][:explorations]).to eq(1)
    end

    it 'boosts urgency on explore' do
      id     = client.create_gap(**gap_args, urgency: 0.4)[:gap][:id]
      result = client.explore_gap(gap_id: id)
      expect(result[:gap][:urgency]).to be > 0.4
    end
  end

  describe '#satisfy_gap' do
    it 'returns found: false for unknown gap_id' do
      result = client.satisfy_gap(gap_id: :ghost)
      expect(result[:found]).to be false
    end

    it 'increases satisfaction' do
      id = client.create_gap(**gap_args)[:gap][:id]
      result = client.satisfy_gap(gap_id: id, amount: 0.5)
      expect(result[:gap][:satisfaction]).to be_within(0.001).of(0.5)
    end

    it 'shows resolved: true when satisfaction crosses threshold' do
      id = client.create_gap(**gap_args)[:gap][:id]
      result = client.satisfy_gap(gap_id: id, amount: 1.0)
      expect(result[:gap][:resolved]).to be true
    end
  end

  describe '#resolve_gap' do
    it 'returns found: false for unknown gap_id' do
      result = client.resolve_gap(gap_id: :ghost)
      expect(result[:found]).to be false
    end

    it 'marks gap as resolved' do
      id     = client.create_gap(**gap_args)[:gap][:id]
      result = client.resolve_gap(gap_id: id)
      expect(result[:resolved]).to be true
    end

    it 'sets satisfaction to 1.0' do
      id = client.create_gap(**gap_args)[:gap][:id]
      client.resolve_gap(gap_id: id)
      expect(client.curiosity_status[:resolved_gaps]).to eq(1)
    end
  end

  describe '#most_urgent_gaps' do
    it 'returns gaps and count' do
      client.create_gap(**gap_args, urgency: 0.9)
      result = client.most_urgent_gaps(limit: 5)
      expect(result).to have_key(:gaps)
      expect(result).to have_key(:count)
    end

    it 'respects limit' do
      3.times { client.create_gap(**gap_args) }
      result = client.most_urgent_gaps(limit: 2)
      expect(result[:count]).to eq(2)
    end

    it 'returns sorted by urgency descending' do
      client.create_gap(**gap_args, urgency: 0.2)
      client.create_gap(**gap_args, urgency: 0.8)
      gaps = client.most_urgent_gaps[:gaps]
      expect(gaps.first[:urgency]).to be >= gaps.last[:urgency]
    end
  end

  describe '#gaps_by_domain' do
    it 'returns gaps matching domain' do
      client.create_gap(question: 'q1', domain: :infra, gap_type: :factual)
      client.create_gap(question: 'q2', domain: :finance, gap_type: :factual)
      result = client.gaps_by_domain(domain: :infra)
      expect(result[:count]).to eq(1)
      expect(result[:domain]).to eq(:infra)
    end
  end

  describe '#gaps_by_type' do
    it 'returns gaps matching type' do
      client.create_gap(question: 'q1', domain: :d, gap_type: :causal)
      client.create_gap(question: 'q2', domain: :d, gap_type: :relational)
      result = client.gaps_by_type(gap_type: :causal)
      expect(result[:count]).to eq(1)
      expect(result[:gap_type]).to eq(:causal)
    end
  end

  describe '#decay_gaps' do
    it 'returns count of decayed gaps' do
      client.create_gap(**gap_args)
      result = client.decay_gaps
      expect(result[:decayed]).to eq(1)
    end

    it 'reduces urgency of gaps' do
      id     = client.create_gap(**gap_args, urgency: 0.5)[:gap][:id]
      before = client.most_urgent_gaps[:gaps].find { |g| g[:id] == id }[:urgency]
      client.decay_gaps
      after = client.most_urgent_gaps[:gaps].find { |g| g[:id] == id }[:urgency]
      expect(after).to be < before
    end
  end

  describe '#curiosity_report' do
    it 'returns a report hash with expected keys' do
      result = client.curiosity_report
      expect(result.keys).to include(:total_gaps, :open_gaps, :resolved_gaps, :information_debt, :exploration_efficiency, :most_urgent)
    end

    it 'reflects current state' do
      client.create_gap(**gap_args)
      expect(client.curiosity_report[:open_gaps]).to eq(1)
    end
  end

  describe '#curiosity_status' do
    it 'returns status hash' do
      result = client.curiosity_status
      expect(result.keys).to include(:total_gaps, :open_gaps, :resolved_gaps, :information_debt, :exploration_efficiency)
    end

    it 'total_gaps reflects all gaps' do
      2.times { client.create_gap(**gap_args) }
      expect(client.curiosity_status[:total_gaps]).to eq(2)
    end

    it 'information_debt is non-negative' do
      client.create_gap(**gap_args, urgency: 0.7)
      expect(client.curiosity_status[:information_debt]).to be >= 0.0
    end
  end
end
