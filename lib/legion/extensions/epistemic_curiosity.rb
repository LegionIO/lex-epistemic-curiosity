# frozen_string_literal: true

require 'legion/extensions/epistemic_curiosity/version'
require 'legion/extensions/epistemic_curiosity/helpers/constants'
require 'legion/extensions/epistemic_curiosity/helpers/knowledge_gap'
require 'legion/extensions/epistemic_curiosity/helpers/curiosity_engine'
require 'legion/extensions/epistemic_curiosity/runners/epistemic_curiosity'

module Legion
  module Extensions
    module EpistemicCuriosity
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
