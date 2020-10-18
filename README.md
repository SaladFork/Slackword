# Slackword

A Slack bot curious about linguistics.

Currently has two sets of features:

- NYT Crossword Clues
- Haiku detection

Only listens in the channels it is in.

## NYT Crossword Clues

To aid when discussing NYT crossword clues, Slackword listens for clue hints
inthe form of `[1a]` (for "1 Across") or `[12d]` (for "12 Down"). A single Slack
message may contain any number of them. It also supports defining a specific
date, which may be specific in only one hint but will affect all the clues in
the message. E.g., (`[Today 12d], [1a], [2d]`) will all show results for the
crossword of the day. `Yesterday` is also supported, as well as any date in any
format Ruby can `Date.parse` including `YYYY-MM-DD`.

## Haiku Detection

Slackword listens in to all messages in any channel it is in, parses each as it
sees them, and if it recognizes all the words in them and knows how many
syllables they have, detects if they fall into a 5-7-5 word break. If so, it
points it out with an emoji reaction and haiku-formatted message. It uses the
open-source
[CMU Pronounciation Dictionary](http://www.speech.cs.cmu.edu/cgi-bin/cmudict)
for its word bank, along with a few custom additions.

# Deploying

Slackword is currently running on Heroku, but can be deployed anywhere. It assumes an environment variable of `SLACK_API_TOKEN` is set (can be set in a `.env`) with the API token the bot should use.
