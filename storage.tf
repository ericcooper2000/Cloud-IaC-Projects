
# Making an s3 bucket that is easy to destroy with a random name.

resource "aws_s3_bucket" "cloudwars" {
  force_destroy = true
}

# Moving an object to an s3 bucket

resource "aws_s3_object" "cloudwars" {
  key = "cloudwars.txt" # File being created
  content = "CloudWars Rules!" # Text inside of file
  bucket = aws_s3_bucket.cloudwars.id # This id attribute references the bucket that the file will be added  to.
}

# Making an azure storage account with resource manager

resource "azurerm_storage_account" "cloudwars" {
  name = "cloudwars12345abcdd"
  account_tier = "Standard"
  account_replication_type = "LRS" #Local Redundant Storage is configured
  resource_group_name = azurerm_resource_group.cloudwars.name
  location = azurerm_resource_group.cloudwars.location
}

# Making a container that is within the azure storage container.

resource "azurerm_storage_container" "cloudwars" {
  name = "cloudwars"
  storage_account_name = azurerm_storage_account.cloudwars.name
}

# Made an blob object and added string inside of it.

resource "azurerm_storage_blob" "cloudwars" {
  name = "cloudwars.txt" #File being created.
  storage_account_name = azurerm_storage_account.cloudwars.name
  storage_container_name = azurerm_storage_container.cloudwars.name
  type = "Block"
  source_content = "Cloudwars Rules!" # Content that is within the object.
}

#Created a Google storage bucket.

resource "google_storage_bucket" "cloudwars" {
  name = "cloudwars-12345abcdd"
  location = "US"
  force_destroy = true
}

# Added an object to the google storage and added strings in it.
resource "google_storage_bucket_object" "cloudwars" {
  name = "cloudwars.txt"
  content = "Cloudwars Rules!"
  bucket = google_storage_bucket.cloudwars.name
}
