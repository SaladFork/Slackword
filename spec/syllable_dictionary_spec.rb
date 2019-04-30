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
         %w["Eureka!" he said]]],

      ["Some haikus have d'oeuvres or words with apostrophes. It should still work though.",
        [%w[Some haikus have d'oeuvres],
         %w[or words with apostrophes.],
         %w[It should still work though.]]]
    ]

    cases.each do |input, expected|
      expect(subject.haiku(input)).to eq([true, expected])
    end
  end
end
