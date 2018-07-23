require 'httparty'

module Slackword
  module Downloaders
    ##
    # A NYTimes Crossword downloader using xwordinfo.com's API
    #
    class NYTimes
      def self.crossword_for(date)
        date
          .yield_self(&method(:download_crossword_for_date))
          .yield_self(&method(:parse_crossword))
      end

      private

      def self.download_crossword_for_date(date)
        HTTParty.get(
          "https://www.xwordinfo.com/JSON/Data.aspx?date=#{date}",
          headers: { 'Referer' => 'slackbot' })
      end

      def self.parse_crossword(crossword_data)
        {
          title: crossword_data['title'],
          clues: {
            across: parse_clues(crossword_data['clues']['across']),
            down:   parse_clues(crossword_data['clues']['down']),
          }
        }
      end

      def self.parse_clues(clues)
        clues.each_with_object({}) do |clue, hash|
          match = clue.match(/\A([0-9]+)\. (.*)\z/)
          hash[match[1].to_i] = match[2]
        end
      end
    end
  end
end
