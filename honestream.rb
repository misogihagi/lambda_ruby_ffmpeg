require 'bundler'
Bundler.require
require "fileutils"

def honestream(input_path)
  movie = FFMPEG::Movie.new(input_path)
  options = {
    video_codec: "copy",
    custom: %w(-codec copy -vbsf h264_mp4toannexb -map 0 -f segment -segment_format mpegts -segment_time 2  -segment_list playlist.m3u8)  
    }
  transcoder_options = { validate: false }
  movie.transcode("%5d.ts",options,transcoder_options)
  
  return  Dir.glob("./*.ts").map { |p| p.slice(2..-1) }.push("playlist.m3u8")
end

