require 'singleton'

class SyllableDictionary
  include Singleton

  CMU_DICT_FILE = File.join(File.dirname(__FILE__), '../data/cmudict-0.7b.txt')

  attr_reader :counts

  def initialize
    cmu_dict_lines =
      File.open(CMU_DICT_FILE)
          .readlines
          .reject{ |line| line.start_with?(';;;') }

    @counts = cmu_dict_lines.each_with_object({}) do |line, syllable_dictionary|
      clean_line = line.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '').chomp
      spelling, arpabet = clean_line.split('  ')

      next if spelling.include?('(')

      syllable_dictionary[spelling] = arpabet.count('0123456789')
    end

    @counts[ '0'] = @counts['ZERO']
    @counts[ '1'] = @counts['ONE']
    @counts[ '2'] = @counts['TWO']
    @counts[ '3'] = @counts['THREE']
    @counts[ '4'] = @counts['FOUR']
    @counts[ '5'] = @counts['FIVE']
    @counts[ '6'] = @counts['SIX']
    @counts[ '7'] = @counts['SEVEN']
    @counts[ '8'] = @counts['EIGHT']
    @counts[ '9'] = @counts['NINE']
    @counts['10'] = @counts['TEN']
  end

  def self.count_syllables(word)
    instance.counts[word.upcase]
  end

  def self.in_dictionary?(word)
    instance.counts.key?(word.upcase)
  end

  def self.haiku(sentence)
    words = sentence.split(/\s/).compact

    return [false, nil] unless words.all?{ |word| in_dictionary?(word) }

    words_with_syllable_counts = words.map{ |word| [word, count_syllables(word)] }

    return [false, nil] unless words_with_syllable_counts.sum(&:last) == 17

    clauses = [[], [], []]
    syllables = [0, 0, 0]

    words_with_syllable_counts.each do |word, word_syllables|
      if syllables[0] < 5
        clauses[0] << word
        syllables[0] += word_syllables
      elsif syllables[1] < 7
        clauses[1] << word
        syllables[1] += word_syllables
      else
        clauses[2] << word
        syllables[2] += word_syllables
      end
    end

    return [false, nil] unless syllables == [5, 7, 5]

    [true, clauses]
  end
end
