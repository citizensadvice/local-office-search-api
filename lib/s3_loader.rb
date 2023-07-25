# frozen_string_literal: true

class S3Loader
  def initialize(s3_client = nil)
    @s3_client = s3_client || Aws::S3::Client.new
  end

  def object_as_io(bucket, key)
    read, write = IO.pipe
    fork do
      read.close
      @s3_client.get_object(bucket:, key:) do |chunk|
        write << chunk.force_encoding("UTF-8")
      end
    end
    write.close
    read
  end
end
