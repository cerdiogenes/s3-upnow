require 'spec_helper'
describe S3UpNow do
  it "version must be defined" do
    S3UpNow::VERSION.should be_true
  end

  it "config must be defined" do
    S3UpNow.config.should be_true
  end

end