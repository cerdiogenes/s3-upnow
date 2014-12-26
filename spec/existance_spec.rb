require 'spec_helper'
describe S3UpNow do
  it "version must be defined" do
    expect(S3UpNow::VERSION).to be
  end

  it "config must be defined" do
    expect(S3UpNow.config).to be
  end

end