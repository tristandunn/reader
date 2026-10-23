# frozen_string_literal: true

RSpec.shared_context "with captured warnings" do
  before do
    allow(Warning).to receive(:warn)
  end
end
