#####distro_sync.rb#####

require_relative 'banner_builder.rb'
require_relative 'colorize.rb'
require 'fileutils'

# Reusable main menu block
main_menu = Proc.new do
	puts "What would you like to do (enter the menu number)?"
	puts "1. Add a new distribution point."
	puts "2. Sync distribution points."
	puts "3. Delete a distribution point."
	puts "4. Change share path of the master distribution point?"
	puts "5. List all servers."
end

class RubyRsyncBuilder

	def initialize
		@filename = "/usr/local/distro_sync/.distro_servers"

		if File.exists?(@filename)
			@master_share = File.open(@filename) {|f| f.readline}
		else
			@master_share = true
		end
			

		# Check if the hidden .distro_servers file exists. If not, check if the directory exists and create it if it doesn't. The file holds the list of servers. 
		until File.file?(@filename) do
			unless File.directory?("/usr/local/distro_sync") 
				Dir.mkdir("/usr/local/distro_sync")
			end
			File.new(@filename, "w")
			if File.zero?(@filename)
				puts "What is the path to your share?"
				share_path = gets.chomp
				if share_path.match(" ")
					share_path.gsub!(/ /, "?")
				end
				if share_path[-1, 1] != "/"
					share_path << "/"
				end
				@master_share = share_path
				File.open(@filename, "a") do |file|
					file.puts share_path
				end
			end
		end
	end

	def add_server
		add_server_banner = BannerBuilder.new("Add a new distribution point")
		add_server_banner.build_banner
		puts "What is the host name of the distribution point?"
		distro_point = gets.chomp
		color_point = distro_point.red
		File.open(@filename, "r") do |file|
			File.foreach(@filename) do |line|
				while line =~ /#{Regexp.escape(distro_point)}/ 
					puts "That server #{color_point} already exists. Please re-enter the server (type 'exit' to exit): "
					distro_point = gets.chomp
					if distro_point == "exit"
						break
					end
				end
			end	
		end
		puts "What is the path to the share on #{distro_point}?"
		distro_path = gets.chomp

		# Replace all spaces in paths with question marks to make rsync happy
		if distro_path.match(" ")
			distro_path.gsub!(/ /, "?")
		end

		# Make sure that all paths end with a forward slash. If not, append on to the end of the string
		if distro_path[-1, 1] != "/"
			distro_path.concat("/")
		end

		puts "What is the username for the share user?"
		share_user = gets.chomp

		# Add the user, server, and path to the .distro_servers file
		File.open(@filename, "a") do |file|
			file.puts "#{share_user}@#{distro_point}:#{distro_path}"
		end
		puts "#{color_point} added!"
		puts "#{distro_path}"
	end

	def delete_server
		delete_server_banner = BannerBuilder.new("Delete a distribution point")
		delete_server_banner.build_banner

		# If delete is confirmed, output the contents of @filename to a temporary file, minus the line with the server we want to delete. Then, overwrite the main file with the temp file.
		puts "Which server would you like to delete?"
		server_to_delete = gets.chomp
		color_to_delete = server_to_delete.red
		if File.readlines(@filename).grep(/#{Regexp.escape(server_to_delete)}/).size > 0

			temp_file = "/usr/local/distro_sync/.temp_servers_file"
			puts "Are you sure you want to delete #{color_to_delete} (plese type yes or no)?"
			delete_a = gets.chomp
			delete_a.downcase!
			if delete_a == "yes"	
				File.open(temp_file, "w") do |file|
					File.foreach(@filename) do |line|
						file.puts line unless line =~ /#{Regexp.escape(server_to_delete)}/
					end
				end
				FileUtils.cp(temp_file, @filename)
				File.delete(temp_file)
			else
				puts "#{server_to_delete.red} was note deleted."
			end
		else
			puts "#{server_to_delete.red} does not exist"
			delete_server
		end
	end


	def change_share_path

		change_share_banner = BannerBuilder.new("Change the master share path")
		change_share_banner.build_banner
		puts "What is your new share path?"
		new_share = gets.chomp
		if new_share.match(" ")
			new_share.gsub!(/ /, "?")
		end
		if new_share[-1, 1] != "/"
			new_share << "/"
		end				
		temp_file = "/usr/local/distro_sync/.temp_servers_file"
		File.open(temp_file, "w") do |file|
			file.puts new_share
			File.foreach(@filename) do |line|
				file.puts line unless line =~ /#{Regexp.escape(@master_share)}/
			end
		end
		FileUtils.cp(temp_file, @filename)
		File.delete(temp_file)
	end

	def perform_sync

		perform_sync_banner = BannerBuilder.new("Sync your distribution points")
		perform_sync_banner.build_banner
		File.foreach(@filename) do |line|
			if line !~ /:/
				next
			end
			# If the server cannot be reached via ping, it will not sync. May need to take this out. Should talk to someone about it.
			#ping_count = 10
			#remote_serv = line.gsub(/:/i, "@").split("@").map(&:strip).reject(&:empty?)
			#remote_serv = remote_serv[1]
			#result = `ping -q -c #{ping_count} #{remote_serv}`
			#if ($?.exitstatus != 0)
			#	puts "Cannot reach #{remote_serv.red}. Moving on to the next one."
			#	next
			#end
			master_share = @master_share.chomp
			`rsync -avrpogz --no-perms --delete -e ssh #{master_share} #{line}`

		end
		puts "All servers are synced.".red
	end

	def automate_sync
		# may not make it into 1.0
	end

	def list_servers
		puts
		File.foreach(@filename) do |line|
			if line !~ /:/
				next
			end
			### Fix this to split the line at both the @ and the :
			#line_array = line.split(":")
			#puts "#{line_array[2]}@" + line_array[0].red + ":#{line_array[1]}"
		
			puts line.chomp.red
		end
		puts
		puts "Press enter to continue: "
		gets
	end
end

response = false
main_banner = BannerBuilder.new("Distro Sync 1.0")
main_banner.build_banner

a = RubyRsyncBuilder.new
until response == "exit" do
	main_menu.call
	response = gets.chomp
	response.downcase!

	case response
	when "1"
		a.add_server
	when "2"
		a.perform_sync
	when "3"
		a.delete_server
	when "4"
		a.change_share_path
	when "5"
		a.list_servers
	when "exit"
		break
	else
		puts "Sorry, that's not a valid entry"
	end
end
