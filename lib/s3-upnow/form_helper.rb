require 's3-upnow/generator'

module S3UpNow
  module S3UpNowHelper
    def s3_upnow_field(object_name, method, options = {})
      generator = S3UpNow::Generator.new(options)
      options[:data] ||= {}
      options[:data][:upnow] = true
      options[:data][:url] = generator.url
      options[:data][:fields] = generator.fields
      hidden_field(object_name, :"#{method}_s3_key", options.slice(:object)) +
      file_field(object_name, method, options)
    end
  end

  module S3UpNowFieldHelper
    def s3_upnow_field(method, options = {})
      self.multipart = true
      @template.s3_upnow_field(@object_name, method, objectify_options(options))
    end
  end
end
