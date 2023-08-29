class DataFile < ActiveRecord::Base
  belongs_to :diagram

  has_attached_file :data_file,
                    :storage => :s3,
                    :s3_permissions => :private,
                    :s3_server_side_encryption => :aes256,
                    :s3_credentials => S3_CREDENTIALS,
                    :s3_region => 'us-west-1',
                    :path => "#{Rails.env == "development" ? "/Users/ceedev/Desktop/ribbon-s3-backup/":""}data_files_flat/:diagram_id/:data_file_id/:filename"
  # "#{Rails.env == "development" ? "/Users/ceedev/Desktop/ribbon-s3-backup/":""}data_files/:institution/:creator_id/:diagram_id/:data_file_id/:filename"

  #{Rails.env == "development" ? "_dev":""}

  validates_attachment_content_type :data_file, :content_type => ["application/json", "text/plain", "text/csv", "application/vnd.ms-excel", "application/octet-stream"]

  private

  Paperclip.interpolates :institution  do |attachment, style|
    attachment.instance.diagram.institution.name
  end

  Paperclip.interpolates :creator_id  do |attachment, style|
    attachment.instance.diagram.creator_id
  end

  Paperclip.interpolates :diagram_id  do |attachment, style|
    attachment.instance.diagram.id
  end

  Paperclip.interpolates :data_file_id  do |attachment, style|
    attachment.instance.id
  end
end
