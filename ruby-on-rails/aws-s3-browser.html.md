* [The Problem](#the-problem)
* [The Solution](#the-solution)
* [The Code](#the-code)
* [Wrap-up](#wrap-up)

## [The Problem](#the-problem)

[Amazon's S3](https://en.wikipedia.org/wiki/Amazon_S3) is a great way to store and organize files, but when I set out to build an S3 browser for my webapp, I had unexpected trouble:  __S3 doesn't have directories.__ Every file has a name, and names can include `/`, but S3 doesn't assign any special meaning to slashes.

```raw
<p class="centered alert alert-info"><strong>How can you browse S3 directories when it doesn't have the concept of directories?</strong></p>
```

## [The Solution](#the-solution)

As anyone who's browsed S3 buckets with the AWS Management Console knows, it's possible to browse S3 directories. The answer is the `prefix` and `delimiter` parameters of [list_objects](http://docs.aws.amazon.com/sdkforruby/api/Aws/S3/Client.html#list_objects-instance_method): you can emulate directories by providing `/` as the delimiter and the parent directory as the prefix.

## [The Code](#the-code)

First, let's jump into the ruby console to learn how the `prefix` and `delimiter` parameters work:

```ruby
# https://github.com/aws/aws-sdk-ruby
# http://docs.aws.amazon.com/sdkforruby/api/index.html
# gem 'aws-sdk'

# setup
s3 = Aws::S3::Resource.new({
  access_key_id: 'your-key',
  secret_access_key: 'your-secret',
  region: 'your-region'
})
bucket = 'your-bucket'
client = s3.client

# root files and directories
root = client.list_objects({
  prefix: '',
  delimiter: '/',
  bucket: bucket,
  encoding_type: 'url'
})

root['contents']        # files
root['common_prefixes'] # directories

# files and directories under /Documents
documents = client.list_objects({
  prefix: 'Documents/',
  delimiter: '/',
  bucket: bucket,
  encoding_type: 'url'
})

documents['contents']        # files
documents['common_prefixes'] # directories
```

We can treat directories and files like a file system by abstracting this rather simple API usage into two classes: `S3::Directory` and `S3::File`

```ruby
# app/models/s3/directory.rb
class S3::Directory

  attr_reader :path

  def initialize(bucket, path)
    @bucket = bucket
    @path = path
  end

  def name
    path_pieces.last
  end

  def parent
    parent_path = path_pieces[0..-2].join('/')
    S3::Directory.new(@bucket, parent_path) unless parent_path.blank?
  end

  def children
    subdirectories + files
  end

  def subdirectories
    @subdirectories ||= list_objects['common_prefixes'].collect do |prefix|
      S3::Directory.new(@bucket, prefix.prefix)
    end
  end

  def files
    @files ||= list_objects['contents'].collect do |object|
      S3::File.new(@bucket, s3_object: object) unless object.key.ends_with?('/')
    end.compact
  end

  private

  def path_pieces
    @path_pieces ||= path ? path.split('/') : []
  end

  def list_objects
    @list_objects ||= @bucket.client.list_objects({
      prefix: @path.blank? ? '' : "#{@path}/",
      delimiter: '/',
      bucket: @bucket.name,
      encoding_type: 'url'
    })
  end

end
```

```ruby
class S3::File

  attr_reader :path

  def initialize(bucket, path)
    @bucket = bucket
    @path = path
  end

  def name
    @name ||= ::File.basename(@path)
  end

  def extension
    @extension ||= ::File.extname(@path)
  end

  def directory
    @directory ||= begin
      dir = ::File.dirname(path)
      dir = nil if dir == '.'
      S3::Directory.new(@bucket, dir)
    end
  end

  def s3_object
    @s3_object ||= @bucket.object(@path)
  end

end
```

## [Wrap-up](#wrap-up)

At first S3 seemed to be lacking an important feature, but after a little research and coding I could move forward on my application's S3 file browser. My S3 learning isn't complete however. Here are some more hurdles I'm anticipating:

* How to create directories?
* How to rename directories?
* How to upload files directly to S3 from a browser?
