module S3UpNow
  module Paperclip
    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        private

        def s3_upnow_attachment(name)
          send(name)
        end

        def s3_upnow_destination_bucket(name)
          attachment = s3_upnow_attachment(name)
          attachment.options[:s3_credentials].try(:[], :bucket) || attachment.options[:bucket].call
        end

        def s3_upnow_destination_path(name)
          s3_upnow_attachment(name).path[1..-1]
        end

        def s3_upnow_destination_permissions(name)
          s3_upnow_attachment(name).s3_permissions
        end
      end
    end
  end

  module ClassMethods
    def has_attached_file(name, options = {})
      self.class_eval do
        attr_accessor "#{name}_s3_key"

        before_validation "s3_upnow_copy_metadata_from_#{name}".to_sym, unless: "#{name}_s3_key.blank?"
        after_save "s3_upnow_copy_file_from_#{name}".to_sym, unless: "#{name}_s3_key.blank?"

        private

        define_method "s3_upnow_copy_metadata_from_#{name}" do
          s3 = AWS::S3.new
          s3_head = s3.buckets[S3UpNow.config.bucket].objects[instance_variable_get("@#{name}_s3_key")].head

          s3_upnow_attachment(name).clear
          self.send "#{name}_file_name=", File.basename(instance_variable_get("@#{name}_s3_key"))
          self.send "#{name}_file_size=", s3_head.content_length
          self.send "#{name}_content_type=", s3_head.content_type
          self.send "#{name}_updated_at=", s3_head.last_modified 
        end

        define_method "s3_upnow_copy_file_from_#{name}" do
          s3 = AWS::S3.new
          orig_bucket = s3.buckets[S3UpNow.config.bucket]
          orig_object = orig_bucket.objects[instance_variable_get("@#{name}_s3_key")]
          dest_bucket = s3.buckets[s3_upnow_destination_bucket(name)]
          dest_object = dest_bucket.objects[s3_upnow_destination_path(name)]
          dest_object.copy_from(orig_object, acl: s3_upnow_destination_permissions(name))
          if s3_upnow_attachment(name).styles.present?
            remove_instance_variable("@#{name}_s3_key")
            s3_upnow_attachment(name).reprocess!
          end
        end
      end
      super(name, options)
    end
  end
end