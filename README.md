To help you set up an automated backup system for PostgreSQL databases, compress them, and upload them to an S3 bucket in AWS, I’ll guide you step by step.
Prerequisites

    AWS Free Account: Ensure you have an AWS free account. If not, sign up at AWS Free Tier.
    PostgreSQL Installed: Your server should have PostgreSQL installed and running.
    AWS CLI Installed: Install the AWS CLI on your server.
    IAM Role/Access Key: You need an AWS IAM user with the necessary permissions to access S3 (for uploading backups).
    Bash Script: You’ll write a bash script to automate the backup and upload process.

Step 1: Install AWS CLI

    Install AWS CLI on your server:

        For Linux (Ubuntu/Debian):

sudo apt update
sudo apt install awscli

For macOS (using Homebrew):

    brew install awscli

    For Windows, you can download and install from AWS CLI Download.

Configure AWS CLI with your IAM credentials:

    Run the following command and enter your AWS Access Key and Secret Key when prompted.

        aws configure

        You'll need to provide:
            AWS Access Key ID
            AWS Secret Access Key
            Default region name (e.g., us-east-1)
            Default output format (e.g., json)

Step 2: Create an S3 Bucket

    Log in to your AWS Management Console.
    Go to the S3 service.
    Click Create bucket.
    Provide a unique bucket name (e.g., my-postgresql-backups).
    Choose a region and click Create.

Step 3: Set Permissions for the S3 Bucket

    Ensure your IAM user has the following permissions:
        s3:PutObject
        s3:ListBucket

    If you’re using the AWS Free Tier, the permissions will be included by default, but make sure your IAM policy looks something like this:

    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "s3:PutObject",
            "s3:ListBucket"
          ],
          "Resource": [
            "arn:aws:s3:::my-postgresql-backups",
            "arn:aws:s3:::my-postgresql-backups/*"
          ]
        }
      ]
    }

Step 4: Write the Bash Script

Here’s a bash script that will:

    Loop through all PostgreSQL databases.
    Backup and compress each database.
    Upload each backup to the S3 bucket.

Bash Script: backup_postgresql.sh

#!/bin/bash

# Define the PostgreSQL user and password
PGUSER="your_pg_user"
PGPASSWORD="your_pg_password"

# Define the S3 bucket name
S3_BUCKET="s3://your-s3-bucket-name"

# Define the backup directory
BACKUP_DIR="/path/to/backup/directory"

# Set PostgreSQL environment variables
export PGPASSWORD=$PGPASSWORD

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Get the list of all databases
databases=$(psql -U $PGUSER -d postgres -t -c "SELECT datname FROM pg_database WHERE datistemplate = false;")

# Loop through all databases
for db in $databases; do
  echo "Backing up database: $db"

  # Define backup file name
  BACKUP_FILE="$BACKUP_DIR/$db-$(date +%Y-%m-%d).sql.gz"

  # Backup the database and compress it
  pg_dump -U $PGUSER -d $db | gzip > $BACKUP_FILE

  # Upload the backup to S3
  aws s3 cp $BACKUP_FILE $S3_BUCKET/

  # Optionally, remove the local backup file after upload
  rm $BACKUP_FILE

  echo "Backup for $db completed and uploaded to S3."
done

# Unset the PostgreSQL password
unset PGPASSWORD

Explanation of the Script:

    PGUSER and PGPASSWORD: Replace these with your PostgreSQL user credentials.
    S3_BUCKET: Replace this with your actual S3 bucket name.
    BACKUP_DIR: This is the local directory where the backups will be stored before uploading to S3.
    pg_dump: This command backs up each PostgreSQL database and compresses it using gzip.
    aws s3 cp: This command uploads the compressed backup to your S3 bucket.
    Cleanup: After uploading, the backup file is deleted from the local directory.

Step 5: Make the Script Executable

    Save the script as backup_postgresql.sh.
    Make it executable:

    chmod +x backup_postgresql.sh

