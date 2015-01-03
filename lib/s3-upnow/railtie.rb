module S3UpNow
  class Railtie < Rails::Railtie
    initializer "railtie.configure_rails_initialization", after: "paperclip.insert_into_active_record" do |app|
      if defined?(ActiveRecord) and defined?(Paperclip)
        ActiveRecord::Base.send(:include, S3UpNow::Paperclip)
      end
      app.middleware.use JQuery::FileUpload::Rails::Middleware
    end
  end
end