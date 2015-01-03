# S3UpNow

[![Build Status](https://travis-ci.org/cerdiogenes/s3-upnow.svg)](https://travis-ci.org/cerdiogenes/s3-upnow)

This is a fork of [s3_direct_upload](https://github.com/waynehoover/s3_direct_upload).

It's also has code from [refile](https://github.com/elabs/refile), mainly
related with the frontend.

The general idea of this gem is to be backend agnostic. I'd liked how
s3_direct_upload interact with S3 and I'd liked how refile interact with the
form and the backend, so I made a hybrid.

For now it's only works with [paperclip](https://github.com/thoughtbot/paperclip).

## Installation
Add this line to your application's Gemfile:

    gem 's3-upnow'

Then add a new initalizer with your AWS credentials:

**config/initializers/s3-upnow.rb**
```ruby
S3UpNow.config do |c|
  c.access_key_id = ""       # your access key id
  c.secret_access_key = ""   # your secret access key
  c.bucket = ""              # your bucket name
  c.region = nil             # region prefix of your bucket url. This is _required_ for the non-default AWS region, eg. "s3-eu-west-1"
  c.url = nil                # S3 API endpoint (optional), eg. "https://#{c.bucket}.s3.amazonaws.com/"
end
```

Make sure your AWS S3 CORS settings for your bucket look something like this:
```xml
<CORSConfiguration>
    <CORSRule>
        <AllowedOrigin>http://0.0.0.0:3000</AllowedOrigin>
        <AllowedMethod>GET</AllowedMethod>
        <AllowedMethod>POST</AllowedMethod>
        <AllowedMethod>PUT</AllowedMethod>
        <MaxAgeSeconds>3000</MaxAgeSeconds>
        <AllowedHeader>*</AllowedHeader>
    </CORSRule>
</CORSConfiguration>
```
In production the AllowedOrigin key should be your domain.

Add the following js to your asset pipeline:

**application.js.coffee**
```coffeescript
#= require s3-upnow
```

## Usage
Create a new view that uses the form helper `s3_upnow_field`:
```ruby
= simple_form_for @model do |f|
  = f.s3_upnow_field :avatar
  = f.button :submit
```

It will create a file field as well a hidden field with `s3_key` suffix. The
code above will generate something like:

``` html
<form action="/models" enctype="multipart/form-data" method="post">
  <input name="model[avatar_s3_key]" type="hidden">
  <input name="model[avatar]" type="file">
</form>
```

As refile, it will also remove the name attribute of the file field on a
successful upload to S3, so it doesn't get submitted with your form. By the way,
this doesn't play well with remote forms. For now I use the following code to
handle this:

```coffeescript
$(document).on('upload:success', 'form', (event) ->
  input = $(event.target)
  form = input.parents('form').clone()
  form.find(input).remove()
  $.rails.handleRemote(form)
)
```

I just have one field, and I want to submit it right after I receive the
upload:success event. I don't know how this will be used in frontends, so I
want to have minimal policies for now. So, be warned and write your own code :)

And that's it! All your models that have `has_attached_file :avatar` will copy
the file specified by s3_key to the path expected by paperclip.

## Options for form helper

All these options are still used in code, but the callbacks options doesn't have
any effect. I will polish it when I have some tests written.

* `callback_url:` No default. The url that is POST'd to after file is uploaded to S3. If you don't specify this option, no callback to the server will be made after the file has uploaded to S3.
* `callback_method:` Defaults to `POST`. Use PUT and remove the multiple option from your file field to update a model.
* `callback_param:` Defaults to `file`. Parameter key for the POST to `callback_url` the value will be the full s3 url of the file. If for example this is set to "model[image_url]" then the data posted would be `model[image_url] : http://bucketname.s3.amazonws.com/filename.ext`
* `key:` Defaults to `uploads/{timestamp}-{unique_id}-#{SecureRandom.hex}/${filename}`. It is the key, or filename used on s3. `{timestamp}` and `{unique_id}` are special substitution strings that will be populated by javascript with values for the current upload. `${filename}` is a special s3 string that will be populated with the original uploaded file name. Needs to be at least `"${filename}"`. It is highly recommended to use both `{unique_id}`, which will prevent collisions when uploading files with the same name (such as from a mobile device, where every photo is named image.jpg), and a server-generated random value such as `#{SecureRandom.hex}`, which adds further collision protection with other uploaders.
* `key_starts_with:` Defaults to `uploads/`. Constraint on the key on s3.  if you change the `key` option, make sure this starts with what you put there. If you set this as a blank string the upload path to s3 can be anything - not recommended!
* `acl:` Defaults to `public-read`. The AWS acl for files uploaded to s3.
* `max_file_size:` Defaults to `500.megabytes`. Maximum file size allowed.
* `id:` Optional html id for the form, its recommended that you give the form an id so you can reference with the jQuery plugin.
* `class:` Optional html class for the form.
* `data:` Optional html data attribute hash.
* `bucket:` Optional (defaults to bucket used in config).

## Cleaning old uploads on S3

PS.: I don't test if it's already working, but I intend to do it soon.

You may be processing the files upon upload and reuploading them to another
bucket or directory. If so you can remove the originali files by running a
rake task.

First, add the fog gem to your `Gemfile` and run `bundle`:
```ruby
  gem 'fog'
```

Then, run the rake task to delete uploads older than 2 days:
```
  $ rake s3-upnow:clean_remote_uploads
  Deleted file with key: "uploads/20121210T2139Z_03846cb0329b6a8eba481ec689135701/06 - PCR_RYA014-25.jpg"
  Deleted file with key: "uploads/20121210T2139Z_03846cb0329b6a8eba481ec689135701/05 - PCR_RYA014-24.jpg"
  $
```

Optionally customize the prefix used for cleaning (default is
`uploads/#{2.days.ago.strftime('%Y%m%d')}`):

**config/initalizers/s3-upnow.rb**
```ruby
S3UpNow.config do |c|
  # ...
  c.prefix_to_clean = "my_path/#{1.week.ago.strftime('%y%m%d')}"
end
```

Alternately, if you'd prefer for S3 to delete your old uploads automatically,
you can do so by setting your bucket's [Lifecycle Configuration](http://docs.aws.amazon.com/AmazonS3/latest/UG/LifecycleConfiguration.html).

## Contributing / TODO
This is just a simple gem that only really provides some javascript and a form
helper. This gem could go all sorts of ways based on what people want and how
people contribute.

Ideas:
* More specs!
* More options to control file types, ability to batch upload.
* More convention over configuration on frontend side


## Credit
This gem is a hybrid of [s3_direct_upload](https://github.com/waynehoover/s3_direct_upload)
and [refile](https://github.com/elabs/refile). Maybe it have more personality in
the future.