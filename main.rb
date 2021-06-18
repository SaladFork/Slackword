require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require 'dotenv/load'

require 'date'
require 'slack-ruby-bot'

require_relative './lib/downloaders/nytimes'
require_relative './lib/syllable_dictionary'

module Slackword
  class Bot < SlackRubyBot::Bot
    KNOWN_CROSSWORDS = {}

    # TODO: Support Crosswords other than NYT
    scan(/\[(?:([a-z0-9\/\-]+)\b )?([0-9]+)([ad])\]/i) do |client, data, matches|
      client.typing(channel: data.channel)

      results = parse_matches(matches)

      begin
        date = case results[:date].downcase
               when 'today';     Date.today
               when 'yesterday'; Date.today.prev_day
               else;             Date.parse(results[:date])
               end
      rescue ArgumentError
        client.say(text: "Sorry <@#{data.user}>, not sure what date you meant by '#{results[:date]}'.", channel: data.channel)
        return
      end

      KNOWN_CROSSWORDS[date] ||= Slackword::Downloaders::NYTimes.crossword_for(date)
      crossword = KNOWN_CROSSWORDS[date]

      text = "*#{crossword[:title]}*"

      [:across, :down].each do |direction|
        next if results[direction].empty?
        text << "\n>*#{direction.capitalize}*"
        results[direction].each do |clue_num|
          text << "\n>   #{clue_num}. #{crossword[:clues][direction][clue_num]}"
        end
      end

      client.say(text: text, channel: data.channel)
    end

    command 'analyze' do |client, data, match|
      subject = match['expression'].strip

      words = SyllableDictionary.split_sentence(subject)

      text = words.map do |word|
        normalized = SyllableDictionary.normalize(word)
        count = SyllableDictionary.count_syllables(normalized)

        syllable_count = count && count.positive? ? "#{count} #{count == 1 ? 'syllable' : 'syllables'}" : 'NOT FOUND'

        [
          '●',
          "`#{word}`",
          '->',
          "`#{normalized}`",
          ' | ',
          syllable_count
        ].join(' ')
      end.join("\n")

      is_haiku, haiku_clauses = SyllableDictionary.haiku(subject)

      if is_haiku
        text << "\nFound haiku:\n"
        text << haiku_clauses
                  .map{ |clause| "> #{clause.join(' ')}" }
                  .join("\n")
      end

      attachments = [
        {
          title: 'Haiku Detection',
          text: text,
          color: is_haiku ? '#02AC1E' : '#B00B1E'
        }
      ]

      client.web_client.chat_postMessage(
        channel: data.channel,
        text: "Analyzing `#{subject}`",
        as_user: true,
        attachments: attachments.to_json
      )
    end

    # Haiku bot
    match(/\A(?<phrase>.*)\z/) do |client, data, match|
      handle_haiku(client, data, match[:phrase])
      handle_alphabetical_phrase(client, data, match[:phrase])
    end

    private_class_method def self.parse_matches(matches)
      matches.each_with_object(date: Date.today.to_s, across: [], down: []) do |(date_maybe, clue, direction), hash|
        hash[:date] = date_maybe unless date_maybe.nil? || date_maybe.empty?

        direction = case direction.downcase
                    when 'a', 'across'; :across
                    when 'd', 'down';   :down
                    end

        hash[direction] << clue.to_i
      end.tap do |results|
        results[:across].sort!
        results[:down].sort!
      end
    end

    private_class_method def self.handle_haiku(client, data, potential_haiku_phrase)
      is_haiku, haiku_clauses = SyllableDictionary.haiku(potential_haiku_phrase)

      return unless is_haiku

      client.web_client.reactions_add(
        name: :star,
        channel: data.channel,
        timestamp: data.ts,
        as_user: true
      )

      thread_text =
        haiku_clauses
          .map{ |clause| "> #{clause.join(' ')}" }
          .join("\n")

      # Post the haiku message to a specific channel
      client.web_client.chat_postMessage(
        channel: '#found-poetry',
        text: "A haiku by <@#{data.user}> in <##{data.channel}>:\n#{thread_text}",
        as_user: true
      )
    end

    private_class_method def self.handle_alphabetical_phrase(client, data, potential_alphabetical_phrase)
      words = potential_alphabetical_phrase.split(/[\s_]/).compact
      # Must have at least 3 words
      return unless words.length >= 3

      # Must have at least one word of at least 3 characters
      return unless words.any? { |word| word.length >= 3 }

      # All words must be in the dictionary
      return unless words.all? { |word| SyllableDictionary.in_dictionary?(word) }

      # Each word must be alphabetical
      return unless words.all? { |word| word_is_alphabetical(word) }

      client.web_client.reactions_add(
        name: :thinking_face,
        channel: data.channel,
        timestamp: data.ts,
        as_user: true
      )
    end

    private_class_method def self.word_is_alphabetical(word)
      word.chars.sort.join == word
    end
  end
end

Slackword::Bot.run
