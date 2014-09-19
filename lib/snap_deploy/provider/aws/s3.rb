require 'timeout'
require 'json'

class SnapDeploy::Provider::AWS::S3 < Clamp::Command

  option '--bucket',
    'BUCKET_NAME',
    'S3 Bucket.',
    :required => true

  option '--region',
    "REGION",
    'EC2 Region.',
    :default => 'us-east-1'

  option '--endpoint',
    'ENDPOINT',
    'S3 Endpoint.',
    :default => 's3.amazonaws.com'

  option '--local-dir',
    "LOCAL_DIR",
    'The local directory. e.g. `~/build/s3` (absolute) or `_site` (relative)',
    :default => Dir.pwd

  option '--remote-dir',
    'REMOTE_DIR',
    'The remote s3 directory to upload to.',
    :default => '/'

  option '--detect-encoding',
    :flag,
    'Set HTTP header `Content-Encoding` for files compressed with `gzip` and `compress` utilities.',
    :default => nil

  option '--cache-control',
    'CACHE_OPTION',
    'Set HTTP header `Cache-Control` to suggest that the browser cache the file. Valid options are `no-cache`, `no-store`, `max-age=<seconds>`, `s-maxage=<seconds>`, `no-transform`, `public`, `private`.',
    :default => 'no-cache'

  option '--expires',
    'WHEN',
    'This sets the date and time that the cached object is no longer cacheable. The date must be in the format `YYYY-MM-DD HH:MM:SS -ZONE`',
    :default => nil

  option '--acl',
    'ACL',
    'Sets the access control for the uploaded objects. Valid options are `private`, `public_read`, `public_read_write`, `authenticated_read`, `bucket_owner_read`, `bucket_owner_full_control`.',
    :default => 'private'

  option '--include-dot-files',
    :flag,
    'When set, upload files starting a `.`.'

  option '--index-document',
    'DOCUMENT_NAME',
    'Set the index document of a S3 website.'

  include SnapDeploy::CLI::DefaultOptions
  include SnapDeploy::Helpers

  def execute
    require 'aws-sdk'
    require 'mime-types'

    glob_args = ["**/*"]
    glob_args << File::FNM_DOTMATCH if include_dot_files?

    Dir.chdir(local_dir) do
      Dir.glob(*glob_args) do |filename|
        content_type = MIME::Types.type_for(filename).first.to_s
        opts         = { :content_type => content_type }.merge(encoding_option_for(filename))
        opts[:cache_control] = cache_control if cache_control
        opts[:acl]           = acl if acl
        opts[:expires]       = expires if expires
        unless File.directory?(filename)
          client.buckets[bucket].objects.create(upload_path(filename), File.read(filename), opts)
        end
      end
    end

    if index_document
      client.buckets[bucket].configure_website do |cfg|
        cfg.index_document_suffix = index_document
      end
    end
  end

  private

  def upload_path(filename)
    [remote_dir, filename].compact.join("/")
  end

  def client
    @client ||= begin
      AWS.config(access_key_id: access_key_id, secret_access_key: secret_access_key, region: region)
      info "Logging in with Access Key: #{access_key_id[-4..-1].rjust(20, '*')}"
      AWS::S3.new(endpoint: endpoint)
    end
  end

  def encoding_option_for(path)
    if detect_encoding? && encoding_for(path)
      {:content_encoding => encoding_for(path)}
    else
      {}
    end
  end

end
