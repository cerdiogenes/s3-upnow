require "spec_helper"

describe S3UpNow::Generator do
  describe "policy_data" do
    describe "starts-with $key" do
      it "is configurable with the key_starts_with option" do
        key_starts_with = "uploads/"
        generator = S3UpNow::Generator.new({:key_starts_with => key_starts_with})
        expect(generator.policy_data[:conditions]).to include ["starts-with", "$key", key_starts_with]
      end

      it "defaults to 'uploads/'" do
        generator = S3UpNow::Generator.new({})
        expect(generator.policy_data[:conditions]).to include ["starts-with", "$key", "uploads/"]
      end
    end

    describe "starts-with $content-type" do
      it "is configurable with the content_type_starts_with option" do
        content_type_starts_with = "image/"
        generator = S3UpNow::Generator.new({:content_type_starts_with => content_type_starts_with})
        expect(generator.policy_data[:conditions]).to include ["starts-with", "$content-type", content_type_starts_with]
      end

      it "is defaults to an empty string" do
        generator = S3UpNow::Generator.new({})
        expect(generator.policy_data[:conditions]).to include ["starts-with", "$content-type", ""]
      end
    end
  end
end