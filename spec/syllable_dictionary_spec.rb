require_relative '../lib/syllable_dictionary.rb'

RSpec.describe SyllableDictionary do
  subject{ SyllableDictionary }

  it 'can detect haikus' do
    cases = [
      ['This is a haiku. Nothing fancy about it. But it sure is one.',
       [%w[This is a haiku.],
        %w[Nothing fancy about it.],
        %w[But it sure is one.]]],

      ["Moonlight cast shadows\nDiodes illuminated\n\"Eureka!\" he said",
       [%w[Moonlight cast shadows],
        %w[Diodes illuminated],
        ['"Eureka!"', 'he', 'said']]]
    ]

    cases.each do |input, expected|
      expect(subject.haiku(input)).to eq([true, expected])
    end
  end
end
