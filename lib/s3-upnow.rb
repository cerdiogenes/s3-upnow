require 's3-upnow/version'
require 'jquery-fileupload-rails' if defined?(Rails)

require 'base64'
require 'openssl'
require 'digest/sha1'

require 's3-upnow/config_aws'
require 's3-upnow/form_helper'
require 's3-upnow/engine' if defined?(Rails)
require 's3-upnow/railtie' if defined?(Rails)

ActionView::Base.send(:include, S3UpNow::UpNowHelper) if defined?(ActionView::Base)
ActionView::Helpers::FormBuilder.send(:include, S3UpNow::UpNowFieldHelper)