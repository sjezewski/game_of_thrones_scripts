#!/usr/bin/env ruby

$DEBUG=false

def normalize
    Dir.glob("raw/*.txt").each do |file|
		puts "Normalizing #{file}"
		normalize_file(file)
	end

end

$character_line = /^([A-Z\s]+?)[\(\)a-z\s]*?\:(.*?)$/

# Either character / exposition
def line_type(line)

	# Examples:
	# BRAN (looking down): I promise.
	# THE HOUND: It’s not hunting if you pay for it.
	# TYRION: The greatest in the land. My spear never misses.
	# SEPTA MORDANE (to SANSA): Fine work, as always. Well done.

	if line =~ /^([\(\)\w\s]*?)\:(.*?)$/
		return :character_line
	end

	return :exposition
end

def parse_character_line(line)
	name = nil
	text = nil

	# Some examples
	tokens = line.split(":")
	if tokens.first =~ /^(.+?)($|\()/
		name = $1
	end

	if tokens.size >= 2
		# e.g. JAIME: As your brother, I feel it’s my duty to warn you: You
		# worry too much. It’s starting to show.
		text = tokens[1..-1].join(" ")
	end

	dputs "Error parsing name from line (#{line})" if name.nil?
	dputs "Error parsing text from line (#{line})" if text.nil?

	# remove spaces from names, and upcase them for consistency
	name.strip!
	name.gsub!(" ","_")
	name.upcase!

	#### Normalize text

	text = normalize_text(text)

	return "<boname> " + name + " <eoname> " + text.split().join(" ")
end

def normalize_text(text)
	# Examples
	# NED: Hey,, hey, hey, hey. What are you doing with that on? [Pulls off ARYA’s helm]
	# CATELYN: Where’s Arya? Sansa, where’s your sister?
	# Should I wrap character names within text in tokens? e.g. this line:
	# [As he speaks, a CREATURE with glowing blue eyes rises behind ROYCE. ROYCE
	# turns, the CREATURE strikes. The scene shifts to WILL, who hears a man
	# crying out. The three horses stampede past him. He turns and sees someone
	# standing very still in the distance. The figure turns – it’s the child who
	# had been suspended in the tree, now with glowing blue eyes. WILL turns and
	#	runs.]
	text.gsub!(".", " <eos>")
	text.gsub!("?", " <question>")
	text.gsub!("!", " <exclamation>")
	text.gsub!(",", " , ") # Make sure to split commas from words
	text.gsub!("'", " '") # Separate contractions
	text.gsub!("’", " '") # Fucking MS word and its apostrophe
	text.gsub!("[", "<open-brack> ")
	text.gsub!("]", " <close-brack>")
	text.gsub!("\u2026", "<ellipsis>")
	text.gsub!("\u201C", "<boquote>")
	text.gsub!("\u201D", "<eoquote>")
	text
end

def parse_exposition_line(line)
	# Exposition
	# - should these have separate beginning / end tokens?
	# - seen lines that are contained in [ brackets ]
	# - seen tokens for beginning and end of episode / season

	# Examples of things we skip:
	# JON/ROBB: Quick, Bran, faster!
	if line =~ /[\w\/]*?\:/
		return nil
	end

	text = nil
	if line =~ /\[(.*?)\]/
		text = $1
	end

	# Some lines are missing end brackets:
	# [As he speaks, a CREATURE with glowing blue eyes rises behind ROYCE. ROYCE turns, the CREATURE strikes. The scene shifts to WILL, who hears a man crying out. The three horses stampede past him. He turns and sees someone standing very still in the distance. The figure turns – it’s the child who had been suspended in the tree, now with glowing blue eyes. WILL turns and runs.
	# This line actually gets split over line breaks ... don't want to
	# complicate top level parsing, so will just accomodate missing open or closed
	# brackets

	if text.nil?
		if line =~ /\[(.*?)/
			text = $1
		end
		if line =~ /(.*?)\]/
			text = $1
		end
	end

	# Example high level exposition token lines:
	# / BLACKOUT /
	# [Blackout / Opening credits]
	if line =~ /^\/(.*?)\//
		# convert action into a token
		text = "<#{$1.strip}>"
	end

	if text.nil? 
		dputs "Error parsing brackets from exposition line (#{line})"
		text = line
	end

	text = normalize_text(text)
	["<open-exp>", text.split().join(" "), "<close-exp>"].join(" ")
end

def normalize_file(raw_file_name)
	contents = []

	contents = File.read(raw_file_name).split("\n").collect do |line|
		next if line.size == 0
		dputs "Calling #{line_type(line)} w line (#{line})"
		if line_type(line) == :character_line
			parse_character_line(line)
		else
			parse_exposition_line(line)
		end
	end

	contents << "<eoepisode>"
	new_file_name = raw_file_name.gsub("raw","normalized")
	f = File.new(new_file_name, "w")
	f << contents.compact.join("\n")
end

def dputs(s)
	puts s if $DEBUG
end

normalize()

%x`cat normalized/*.txt > all.txt`

all = File.read("all.txt")

episodes = all.split("<eoepisode>")

# 80% to training
# 10% to test
# 10% to valid

test = episodes.size / 10
valid = test * 2

File.open("ptb.test.txt", "w") << episodes[0..(test-1)].join("<eoepisode>")
File.open("ptb.valid.txt", "w") << episodes[test..(valid-1)].join("<eoepisode>")
File.open("ptb.train.txt", "w") << episodes[valid..-1].join("<eoepisode>")

%x`tar -c *.txt > GoT-scripts.tar`
%x`gzip GoT-scripts.tar`



