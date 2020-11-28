require 'bundler'
Bundler.require

def lambda_handler(event,context=nil)
  ENV['PATH']=ENV['PATH']+":/var/task"
  `ffmpeg -version`
end

