# rubocop:disable RSpec/SpecFilePathFormat
require "rails_helper"
require "stringio"

load Rails.root.join("bin/check-outdated")

RSpec.describe DependencyFreshnessCheck do
  describe ".run" do
    subject(:result) do
      described_class.run(stdout: output, shell_runner: lambda { |*command|
        calls << command
        statuses.fetch(command)
      })
    end

    let(:calls) { [] }
    let(:output) { StringIO.new }
    let(:statuses) do
      {
        [ "bundle", "outdated", "--strict" ] => false,
        [ "bin/npm", "outdated" ] => true
      }
    end

    it "runs every dependency check and returns non-zero if any check fails" do
      expect(result).to eq(1)
      expect(calls).to eq(
        [
          [ "bundle", "outdated", "--strict" ],
          [ "bin/npm", "outdated" ]
        ]
      )
      expect(output.string).to include("bundle outdated --strict", "bin/npm outdated")
    end

    it "returns zero when all dependency checks succeed" do
      result = described_class.run(shell_runner: ->(*) { true })

      expect(result).to eq(0)
    end
  end

  describe ".run_cli" do
    it "exits with the aggregate status code" do
      allow(described_class).to receive(:run).and_return(4)

      expect { described_class.run_cli }.to raise_error(SystemExit) do |error|
        expect(error.status).to eq(4)
      end
    end
  end
end
# rubocop:enable RSpec/SpecFilePathFormat
