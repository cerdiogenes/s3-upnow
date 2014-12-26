# encoding: utf-8

module S3UpNow
  class Generator
    def initialize(options)
      @key_starts_with = options[:key_starts_with] || "uploads/"
      @options = options.reverse_merge(
        aws_access_key_id: S3UpNow.config.access_key_id,
        aws_secret_access_key: S3UpNow.config.secret_access_key,
        bucket: options[:bucket] || S3UpNow.config.bucket,
        region: S3UpNow.config.region || "s3",
        url: S3UpNow.config.url,
        ssl: true,
        acl: "public-read",
        expiration: 10.hours.from_now.utc.iso8601,
        max_file_size: 500.megabytes,
        callback_method: "POST",
        callback_param: "file",
        key_starts_with: @key_starts_with,
        key: key
      )
    end

    def fields
      {
        :utf8 => '✓',
        :key => @options[:key] || key,
        :acl => @options[:acl],
        "AWSAccessKeyId" => @options[:aws_access_key_id],
        :policy => policy,
        :signature => signature,
        :success_action_status => "201",
        'X-Requested-With' => 'xhr'
      }
    end

    def key
      @key ||= "#{@key_starts_with}{timestamp}-{unique_id}-#{SecureRandom.hex}/${filename}"
    end

    def url
      @options[:url] || "http#{@options[:ssl] ? 's' : ''}://#{@options[:region]}.amazonaws.com/#{@options[:bucket]}/"
    end

    def policy
      Base64.encode64(policy_data.to_json).gsub("\n", "")
    end

    def policy_data
      {
        expiration: @options[:expiration],
        conditions: [
          ["starts-with", "$utf8", ""],
          ["starts-with", "$key", @options[:key_starts_with]],
          ["starts-with", "$x-requested-with", ""],
          ["content-length-range", 0, @options[:max_file_size]],
          ["starts-with","$content-type", @options[:content_type_starts_with] ||""],
          {bucket: @options[:bucket]},
          {acl: @options[:acl]},
          {success_action_status: "201"}
        ] + (@options[:conditions] || [])
      }
    end

    def signature
      Base64.encode64(
        OpenSSL::HMAC.digest(
          OpenSSL::Digest.new('sha1'),
          @options[:aws_secret_access_key], policy
        )
      ).gsub("\n", "")
    end
  end
end