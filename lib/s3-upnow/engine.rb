module S3UpNow
  class Engine < ::Rails::Engine 
    initializer "s3-upnow.setup", before: :load_environment_config do
      ActionView::Base.send(:include, S3UpNow::S3UpNowHelper) if defined?(ActionView::Base)
      ActionView::Helpers::FormBuilder.send(:include, S3UpNow::S3UpNowFieldHelper)
    end
  end
end