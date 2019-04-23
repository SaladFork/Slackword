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

    # Haiku bot
    match(/\A(?<phrase>.*)\z/) do |client, data, match|
      is_haiku, haiku_clauses = SyllableDictionary.haiku(match[:phrase])

      if is_haiku
        client.web_client.reactions_add(
          name: :thumbsup,
          channel: data.channel,
          timestamp: data.ts,
          as_user: true
        )

        # thread_text =
        #   haiku_clauses
        #   .map{ |clause| "> #{clause.join(' ')}" }
        #   .join("\n")

        # client.say(
        #   channel: data.channel,
        #   text: thread_text,
        #   thread_ts: data.thread_ts || data.ts
        # )
      end
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
  end
end

Slackword::Bot.run
