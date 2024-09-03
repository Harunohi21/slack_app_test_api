require 'aws-sdk-s3'

Aws.config.update({
  region: 'us-east-1', # MinIO requires a region setting, but it's not used.
  credentials: Aws::Credentials.new('minio', 'miniosecret'),
  endpoint: 'http://minio:9000', # MinIO server endpoint
  force_path_style: true # This is important for MinIO
})
