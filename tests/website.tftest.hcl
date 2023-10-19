# When you ran the tests, Terraform performed the following actions:

# Ran an apply on the setup helper module to create a random_pet resource.
# Applied your main module to create the S3 bucket and upload the website files.
# Ran the three assertions to check the bucket name and the hashes of the index.html and error.html files.
# Destroyed the test-specific S3 resources it created from the main configuration.
# Destroyed the helper module resources.



# Optional Module. Call the setup module to create a random bucket prefix
# The first run block, named "setup_tests", runs a terraform apply command on
# the setup helper module to create the random bucket prefix. Each run block requires a unique name.

run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

# Apply run block to create the bucket
run "create_bucket" {
  variables {
    bucket_name = "${run.setup_tests.bucket_prefix}-aws-s3-website-test"
  }

# The run block then defines three assertions. The condition of each assert block must evaluate to true, 
# otherwise the test will fail and display the error_message.
# A run block may contain multiple assert blocks, but every assert block must evaluate to true for the run block to pass.
#  Your decision to split multiple assert blocks into separate run blocks should be based on what is 
# most clear to the module developers. Remember that every run block performs either a terraform plan or terraform apply.
# In general, a run block can be thought of as a step in a test, and each assert block validates that step.


  # Check that the bucket name is correct
  assert {
    condition     = aws_s3_bucket.s3_bucket.bucket == "${run.setup_tests.bucket_prefix}-aws-s3-website-test"
    error_message = "Invalid bucket name"
  }

  # Check index.html hash matches
  assert {
    condition     = aws_s3_object.index.etag == filemd5("./www/index.html")
    error_message = "Invalid eTag for index.html"
  }

  # Check error.html hash matches
  assert {
    condition     = aws_s3_object.error.etag == filemd5("./www/error.html")
    error_message = "Invalid eTag for error.html"
  }
}

# This test uses the final helper module and references the website_endpoint output from the main module 
# for the endpoint variable. It also defines one assert block to check that the HTTP GET request responds with a 200 status code,
#  indicating that the website is running properly.

run "website_is_running" {
  command = plan

  module {
    source = "./tests/final"
  }

  variables {
    endpoint = run.create_bucket.website_endpoint
  }

  assert {
    condition     = data.http.index.status_code == 200
    error_message = "Website responded with HTTP status ${data.http.index.status_code}"
  }
}

