require 'cinch'
require 'json'
require 'open-uri'

TWITTER_LINK_REGEXP = /(?:(?:http(?:s)?\:\/\/)?(?:www\.)?twitter\.com\/[^\/]+?\/status\/\d+)/
TWITTER_NUM_REGEXP = /(?:(?:http(?:s)?\:\/\/)?(?:www\.)?twitter\.com\/[^\/]+?\/status\/(\d+))/
TWITTER_NAME_REGEXP = /(?:(?:http(?:s)?\:\/\/)?(?:www\.)?twitter\.com\/([^\/]+?)\/status\/\d+)/

bot = Cinch::Bot.new do
  configure do |c|
		c.server = "irc.freenode.net"
		c.nick = "dat_bot"
		c.channels = ["#geeks-tn"]
  end
  
  on :message, TWITTER_LINK_REGEXP do |m|
	  link = m.params.last.scan(TWITTER_LINK_REGEXP).first
	  status_num = link.scan(TWITTER_NUM_REGEXP).flatten.first
	  screen_name = link.scan(TWITTER_NAME_REGEXP).flatten.first
	  
	  result = nil
	  
	  begin
		  response = open("https://api.twitter.com/1/statuses/show/#{status_num}.json").read.to_s
	  	result = JSON.parse(response)
	  rescue StandardError => e
		  puts e.to_s
		end
	  
	  if (!result.nil? && (result["user"])["screen_name"] == screen_name)
			m.reply("@#{(result["user"])["screen_name"]}: #{result["text"]}")
		end
  end
  
  on :message, /dat_bot/ do |m|
	  m.reply ":)"
	end
end

bot.start