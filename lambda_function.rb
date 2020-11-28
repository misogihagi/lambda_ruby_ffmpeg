require 'aws-sdk-s3'

require "./honestream"

def s3download(s3_resource, bucket_name, object_key)
  object=Aws::S3::Resource.new(region: s3_resource).bucket(bucket_name).object(object_key)
  file=/[^\/]+$/.match(object_key).string
  object.get(response_target: file)
rescue StandardError => e
  puts "Error downloading object: #{e.message}"
  return e
end


def s3upload(s3_resource, bucket_name, object_key, file_path)
  object=Aws::S3::Resource.new(region: s3_resource).bucket(bucket_name).object(object_key)
  object.upload_file(file_path)
  File.delete(file_path)
rescue StandardError => e
  puts "Error uploading object: #{e.message}"
  return e
end


def lambda_handler(event,context=nil)
  s3_resource=event[:event]["s3_resource"]
  bucket_name=event[:event]["bucket_name"]
  object_key=event[:event]["object_key"]
  ENV['PATH']=ENV['PATH']+":/var/task"
  Dir.chdir('/tmp')
  s3download(s3_resource,bucket_name,object_key)
  file=/[^\/]+$/.match(object_key).string 
  tss=honestream("/tmp/"+file)
  for ts in tss do
    s3upload(s3_resource,bucket_name,object_key+"/"+ts,ts)
  end

end

