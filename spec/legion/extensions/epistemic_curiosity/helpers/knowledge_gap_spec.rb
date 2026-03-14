# frozen_string_literal: true

RSpec.describe Legion::Extensions::EpistemicCuriosity::Helpers::KnowledgeGap do
  subject(:gap) do
    described_class.new(
      id:       :gap_1,
      question: 'Why does the cache miss?',
      domain:   :infrastructure,
      gap_type: :causal,
      urgency:  0.5
    )
  end

  describe '#initialize' do
    it 'sets id' do
      expect(gap.id).to eq(:gap_1)
    end

    it 'sets question' do
      expect(gap.question).to eq('Why does the cache miss?')
    end

    it 'sets domain' do
      expect(gap.domain).to eq(:infrastructure)
    end

    it 'sets gap_type' do
      expect(gap.gap_type).to eq(:causal)
    end

    it 'sets urgency' do
      expect(gap.urgency).to eq(0.5)
    end

    it 'starts satisfaction at 0.0' do
      expect(gap.satisfaction).to eq(0.0)
    end

    it 'starts explorations at 0' do
      expect(gap.explorations).to eq(0)
    end

    it 'sets created_at' do
      expect(gap.created_at).to be_a(Time)
    end

    it 'resolved_at is nil initially' do
      expect(gap.resolved_at).to be_nil
    end

    it 'clamps urgency above 1.0' do
      g = described_class.new(id: :x, question: 'q', domain: :d, gap_type: :factual, urgency: 2.0)
      expect(g.urgency).to eq(1.0)
    end

    it 'clamps urgency below 0.0' do
      g = described_class.new(id: :x, question: 'q', domain: :d, gap_type: :factual, urgency: -1.0)
      expect(g.urgency).to eq(0.0)
    end
  end

  describe '#explore!' do
    it 'increments explorations' do
      gap.explore!
      expect(gap.explorations).to eq(1)
    end

    it 'boosts urgency by URGENCY_BOOST' do
      before = gap.urgency
      gap.explore!
      expect(gap.urgency).to be_within(0.001).of(before + Legion::Extensions::EpistemicCuriosity::Helpers::Constants::URGENCY_BOOST)
    end

    it 'returns self' do
      expect(gap.explore!).to eq(gap)
    end

    it 'does not exceed 1.0 on urgency' do
      g = described_class.new(id: :x, question: 'q', domain: :d, gap_type: :factual, urgency: 0.99)
      g.explore!
      expect(g.urgency).to be <= 1.0
    end
  end

  describe '#satisfy!' do
    it 'increases satisfaction' do
      gap.satisfy!(amount: 0.3)
      expect(gap.satisfaction).to be_within(0.001).of(0.3)
    end

    it 'returns self' do
      expect(gap.satisfy!).to eq(gap)
    end

    it 'clamps satisfaction at 1.0' do
      gap.satisfy!(amount: 0.6)
      gap.satisfy!(amount: 0.6)
      expect(gap.satisfaction).to eq(1.0)
    end

    it 'uses default amount 0.3' do
      gap.satisfy!
      expect(gap.satisfaction).to be_within(0.001).of(0.3)
    end
  end

  describe '#resolved?' do
    it 'returns false when satisfaction is low' do
      expect(gap.resolved?).to be false
    end

    it 'returns true when satisfaction >= SATISFACTION_THRESHOLD' do
      gap.satisfy!(amount: 1.0)
      expect(gap.resolved?).to be true
    end

    it 'returns true at exactly SATISFACTION_THRESHOLD' do
      gap.satisfaction = Legion::Extensions::EpistemicCuriosity::Helpers::Constants::SATISFACTION_THRESHOLD
      expect(gap.resolved?).to be true
    end
  end

  describe '#urgency_label' do
    it 'returns :burning for urgency 0.9' do
      gap.urgency = 0.9
      expect(gap.urgency_label).to eq(:burning)
    end

    it 'returns :intense for urgency 0.7' do
      gap.urgency = 0.7
      expect(gap.urgency_label).to eq(:intense)
    end

    it 'returns :moderate for urgency 0.5' do
      gap.urgency = 0.5
      expect(gap.urgency_label).to eq(:moderate)
    end

    it 'returns :mild for urgency 0.3' do
      gap.urgency = 0.3
      expect(gap.urgency_label).to eq(:mild)
    end

    it 'returns :satisfied for urgency 0.1' do
      gap.urgency = 0.1
      expect(gap.urgency_label).to eq(:satisfied)
    end
  end

  describe '#decay!' do
    it 'decreases urgency by URGENCY_DECAY' do
      before = gap.urgency
      gap.decay!
      expect(gap.urgency).to be_within(0.001).of(before - Legion::Extensions::EpistemicCuriosity::Helpers::Constants::URGENCY_DECAY)
    end

    it 'returns self' do
      expect(gap.decay!).to eq(gap)
    end

    it 'does not go below 0.0' do
      g = described_class.new(id: :x, question: 'q', domain: :d, gap_type: :factual, urgency: 0.01)
      g.decay!
      expect(g.urgency).to eq(0.0)
    end
  end

  describe '#to_h' do
    it 'returns a hash' do
      expect(gap.to_h).to be_a(Hash)
    end

    it 'includes all expected keys' do
      h = gap.to_h
      expect(h.keys).to include(:id, :question, :domain, :gap_type, :urgency, :urgency_label, :satisfaction, :explorations, :resolved, :created_at,
                                :resolved_at)
    end

    it 'rounds urgency to 4 decimal places' do
      gap.urgency = 0.123456789
      expect(gap.to_h[:urgency]).to eq(0.1235)
    end

    it 'includes resolved status' do
      expect(gap.to_h[:resolved]).to be false
    end
  end
end
