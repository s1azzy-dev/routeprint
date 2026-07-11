require "rails_helper"

RSpec.describe Imports::CaptureArtifact, type: :interactor do
  subject(:result) do
    described_class.call(
      input: {
        run:,
        run_item:,
        io: StringIO.new(content),
        filename: "airports.csv",
        content_type: "text/csv",
        kind: "source_dump",
        source_url: "https://example.test/airports.csv"
      }
    )
  end

  let!(:run) { create(:imports_run, status: "running") }
  let!(:run_item) { create(:imports_run_item, run:) }
  let(:content) { "id,name\n1,Example Airport\n" }

  it "stores an immutable artifact with a private attached raw file and checksum" do
    expect { result }.to change(Imports::Artifact, :count).by(1)

    expect(result).to be_success
    artifact = result.value!.fetch(:artifact)
    expect_artifact(artifact)
  end

  private

  def expect_artifact(artifact)
    expect(artifact).to have_attributes(
      run:,
      run_item:,
      kind: "source_dump",
      sha256: Digest::SHA256.hexdigest(content),
      byte_size: content.bytesize,
      content_type: "text/csv",
      source_url: "https://example.test/airports.csv"
    )
    expect(artifact.file).to be_attached
    expect(artifact.file.download).to eq(content)
  end
end
