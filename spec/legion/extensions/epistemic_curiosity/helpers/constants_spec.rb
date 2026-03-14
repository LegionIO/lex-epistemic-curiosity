# frozen_string_literal: true

RSpec.describe Legion::Extensions::EpistemicCuriosity::Helpers::Constants do
  it 'defines MAX_GAPS' do
    expect(described_class::MAX_GAPS).to eq(300)
  end

  it 'defines DEFAULT_URGENCY' do
    expect(described_class::DEFAULT_URGENCY).to eq(0.5)
  end

  it 'defines URGENCY_BOOST' do
    expect(described_class::URGENCY_BOOST).to eq(0.08)
  end

  it 'defines URGENCY_DECAY' do
    expect(described_class::URGENCY_DECAY).to eq(0.03)
  end

  it 'defines SATISFACTION_THRESHOLD' do
    expect(described_class::SATISFACTION_THRESHOLD).to eq(0.8)
  end

  it 'defines all five GAP_TYPES' do
    expect(described_class::GAP_TYPES).to contain_exactly(:factual, :conceptual, :procedural, :causal, :relational)
  end

  it 'GAP_TYPES is frozen' do
    expect(described_class::GAP_TYPES).to be_frozen
  end

  it 'URGENCY_LABELS covers burning range' do
    entry = described_class::URGENCY_LABELS.find { |e| e[:label] == :burning }
    expect(entry[:range]).to cover(0.9)
  end

  it 'URGENCY_LABELS covers satisfied range' do
    entry = described_class::URGENCY_LABELS.find { |e| e[:label] == :satisfied }
    expect(entry[:range]).to cover(0.1)
  end

  it 'URGENCY_LABELS has five entries' do
    expect(described_class::URGENCY_LABELS.size).to eq(5)
  end
end
