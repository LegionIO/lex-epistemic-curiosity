# frozen_string_literal: true

require 'legion/extensions/epistemic_curiosity/client'

RSpec.describe Legion::Extensions::EpistemicCuriosity::Client do
  let(:client) { described_class.new }

  it 'responds to create_gap' do
    expect(client).to respond_to(:create_gap)
  end

  it 'responds to explore_gap' do
    expect(client).to respond_to(:explore_gap)
  end

  it 'responds to satisfy_gap' do
    expect(client).to respond_to(:satisfy_gap)
  end

  it 'responds to resolve_gap' do
    expect(client).to respond_to(:resolve_gap)
  end

  it 'responds to most_urgent_gaps' do
    expect(client).to respond_to(:most_urgent_gaps)
  end

  it 'responds to gaps_by_domain' do
    expect(client).to respond_to(:gaps_by_domain)
  end

  it 'responds to gaps_by_type' do
    expect(client).to respond_to(:gaps_by_type)
  end

  it 'responds to decay_gaps' do
    expect(client).to respond_to(:decay_gaps)
  end

  it 'responds to curiosity_report' do
    expect(client).to respond_to(:curiosity_report)
  end

  it 'responds to curiosity_status' do
    expect(client).to respond_to(:curiosity_status)
  end
end
