require 'cinch'
require 'json'
require 'open-uri'
require 'net/http'

TWITTER_LINK_REGEXP = /(?:(?:https?\:\/\/)?(?:www\.)?twitter\.com\/[^\/]+?\/status\/\d+)/im
TWITTER_NUM_REGEXP = /(?:(?:https?\:\/\/)?(?:www\.)?twitter\.com\/[^\/]+?\/status\/(\d+))/im
TWITTER_NAME_REGEXP = /(?:(?:https?\:\/\/)?(?:www\.)?twitter\.com\/([^\/]+?)\/status\/\d+)/im

YOUTUBE_LINK_REGEXP = /(?:youtube\.com\/watch\?[^\s\/]*?v=[0-9A-Za-z\-]{11})/im
YOUTUBE_VID_ID_REGEXP = /v=([0-9A-Za-z\-]{11})/im

LINK_REGEXP = /(?:https?:\/\/)?(?:[\da-z\.-]+)\.(?:[a-z\.]{2,6})(?:[\/\w\.\?=-]*)\/?/im
DOMAIN_REGEXP = /(?:https?:\/\/)?((?:[\da-z\.-]+)\.(?:[a-z\.]{2,6}))(?:[\/\w\.\?=-]*)\/?/im
URI_REGEXP = /(?:https?:\/\/)?(?:[\da-z\.-]+)\.(?:[a-z\.]{2,6})((?:[\/\w\.\?=-]*)\/?)/im

USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/536.26.17 (KHTML, like Gecko) Version/6.0.2 Safari/536.26.17"

SERVER = "irc.freenode.net"
NICK = "dat_bot"
CHAN = "#----"
LOG_LINK = ""

bot = Cinch::Bot.new do
	configure do |c|
	  c.server = SERVER
	  c.nick = NICK
	  c.channels = [CHAN]
  end
  
  on :message, TWITTER_LINK_REGEXP do |m|
	  link = m.params.last.scan(TWITTER_LINK_REGEXP).flatten.first
	  status_num = link.scan(TWITTER_NUM_REGEXP).flatten.first
	  screen_name = link.scan(TWITTER_NAME_REGEXP).flatten.first
	  
	  result = nil
	  
	  begin
		  response = open("http://api.twitter.com/1/statuses/show/#{status_num}.json").read.to_s
		  result = JSON.parse(response)
	  rescue StandardError => e
		  puts e.to_s
	  end
	  
	  if (!result.nil? && (result["user"])["screen_name"].downcase == screen_name.downcase)
		  m.reply("Tweet by @#{(result["user"])["screen_name"]}: \"#{result["text"]}\"")
	  end
  end
  
  on :message, YOUTUBE_LINK_REGEXP do |m|
	  link = m.params.last.scan(YOUTUBE_LINK_REGEXP).flatten.first
	  vid_id = link.scan(YOUTUBE_VID_ID_REGEXP).flatten.first
  	
	  title = nil
	  user = nil
		  
	  begin
		  response = open("https://gdata.youtube.com/feeds/api/videos/#{vid_id}?v=2&alt=jsonc").read.to_s
		  result = JSON.parse(response)
		  title = (result["data"])["title"]
		  user = (result["data"])["uploader"]
	  rescue StandardError => e
		  puts e.to_s
	  end
  
	  m.reply("YouTube: \"#{title}\" by #{user}") unless title.nil? || user.nil?
  end
  
  on :message, /^\!\s/ do |m|
	  title = catch(:dropit) {
		  link = m.params.last.scan(LINK_REGEXP).flatten.first
		  throw(:dropit) if link.nil? || link.empty?
			
		  domain = link.scan(DOMAIN_REGEXP).flatten.first
		  throw(:dropit) if domain.nil? || domain.empty?
			
		  uri = link.scan(URI_REGEXP).flatten.first
		  if (uri.nil? || !link.end_with?(domain+uri))
			  throw :dropit
		  end
		  uri = "/"+uri unless uri.start_with?("/")
		  result = nil
			
		  begin
				Net::HTTP.start(domain) do |http|
					req = Net::HTTP::Head.new(uri)
					req["User-Agent"] = USER_AGENT
					headers = http.request(req).to_hash
					content_length = headers["content-length"].first.to_i
					location = headers["location"] || link
					
					if (content_length <= 512000) # 500KB
						req = Net::HTTP::Get.new(uri)
						req["User-Agent"] = USER_AGENT
						result = http.request(req).body
						result = result.scan(/<title.*?>(.*?)<\/title>/im).flatten.first
					end
				end
		  rescue StandardError => e
				puts e.to_s
				throw :dropit
		  end
			
		  nil || result
	  }
		
		if (!title.nil?)
		  m.reply "Link: #{title}"
		end
  end
	
  on :message, /#{NICK}/ do |m|
	  m.reply ":)"
  end
	
  on :message, "!log" do |m|
	  m.reply "Here's the channel's IRC log: #{LOG_LINK}"
  end
end

bot.start