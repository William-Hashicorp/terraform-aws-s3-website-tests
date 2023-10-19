provider "aws" {
  region = "us-east-2"
}

# This code defines an AWS S3 bucket with a name sourced from a variable bucket_name
resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.bucket_name
}

# This configures the S3 bucket to act as a static website.
# The bucket will serve index.html as the default index document and error.html for any errors.

resource "aws_s3_bucket_website_configuration" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# This configures public access settings for the S3 bucket.
# The current settings allow public access.

resource "aws_s3_bucket_public_access_block" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

#This sets the ownership controls for the S3 bucket,
# specifying that the bucket owner is preferred as the owner of new objects.

resource "aws_s3_bucket_ownership_controls" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# This sets the access control list (ACL) for the S3 bucket, 
# allowing public read access.

resource "aws_s3_bucket_acl" "s3_bucket" {
  depends_on = [
    aws_s3_bucket_public_access_block.s3_bucket,
    aws_s3_bucket_ownership_controls.s3_bucket,
  ]

  bucket = aws_s3_bucket.s3_bucket.id

  acl = "public-read"
}

# This configures a bucket policy that allows public GetObject access,
#  ensuring that objects in the bucket can be publicly read.

resource "aws_s3_bucket_policy" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource = [
          aws_s3_bucket.s3_bucket.arn,
          "${aws_s3_bucket.s3_bucket.arn}/*",
        ]
      },
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.s3_bucket]
}

# This uploads html files from the local www/ directory to the S3 bucket.

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.s3_bucket.id
  key          = "index.html"
  source       = "www/index.html"
  content_type = "text/html"
}

resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.s3_bucket.id
  key          = "error.html"
  source       = "www/error.html"
  content_type = "text/html"
}
