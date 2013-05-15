#### Casper Diagnostic ####

# Banner Builder

class BannerBuilder

	def initialize(banner_message)
		@banner_message = banner_message
	end

	def build_banner
		banner_array = []
		message_length = @banner_message.length + 14
		line1 = "#" * (message_length)
		line2 = "######" + " #{@banner_message} " + "######"
		line3 = "#" * (message_length)

		puts ""
		puts line1
		puts line2
		puts line3
		puts ""

	end

end
