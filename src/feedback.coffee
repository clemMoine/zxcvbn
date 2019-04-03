scoring = require('./scoring')

feedback =
  default_feedback:
    warning: ''
    suggestions: [
      {
        code: 'use_a_few_words',
        message: 'Use a few words, avoid common phrases'
      },
      {
        code: 'no_need_for_mixed_chars',
        message: 'No need for symbols, digits, or uppercase letters'
      }
    ]

  get_feedback: (score, sequence) ->
    # starting feedback
    return @default_feedback if sequence.length == 0

    # no feedback if score is good or great.
    return if score > 2
      warning: ''
      suggestions: []

    # tie feedback to the longest match for longer sequences
    longest_match = sequence[0]
    for match in sequence[1..]
      longest_match = match if match.token.length > longest_match.token.length
    feedback = @get_match_feedback(longest_match, sequence.length == 1)
    extra_feedback = {
      code: 'add_another_word',
      message: 'Add another word or two. Uncommon words are better.'
    }
    if feedback?
      feedback.suggestions.unshift extra_feedback
      feedback.warning = '' unless feedback.warning?
    else
      feedback =
        warning: ''
        suggestions: [extra_feedback]
    feedback

  get_match_feedback: (match, is_sole_match) ->
    switch match.pattern
      when 'dictionary'
        @get_dictionary_match_feedback match, is_sole_match

      when 'spatial'
        layout = match.graph.toUpperCase()
        warning = if match.turns == 1
          {
            code: 'straight-rows',
            message: 'Straight rows of keys are easy to guess'
          }
        else
          {
            code: 'short-keyboard-patterns',
            message: 'Short keyboard patterns are easy to guess'
          }
        warning: warning
        suggestions: [
          {
            code: 'use-longer-keyboard-pattern',
            message: 'Use a longer keyboard pattern with more turns'
          }
        ]

      when 'repeat'
        warning = if match.base_token.length == 1
          {
            code: 'repeats-aaa',
            message: 'Repeats like "aaa" are easy to guess'
          }
        else
          {
            code: 'repeats-abcabcabc',
            message:
              'Repeats like "abcabcabc" are only slightly harder to guess than "abc"'
          }
        warning: warning
        suggestions: [
          {
            code: 'avoid-repeated-words',
            message: 'Avoid repeated words and characters'
          }
        ]

      when 'sequence'
        warning: {
          code: 'sequences-abc-6543',
          message: 'Sequences like abc or 6543 are easy to guess'
        }
        suggestions: [
          {
            code: 'avoid-sequences',
            message: 'Avoid sequences'
          }
        ]

      when 'regex'
        if match.regex_name == 'recent_year'
          warning: {
            code: 'recent-years',
            message: 'Recent years are easy to guess'
          }
          suggestions: [
            {
              code: 'avoid-recent-years',
              message: 'Avoid recent years'
            },
            {
              code: 'avoid-personnal-years',
              message: 'Avoid years that are associated with you'
            }
          ]

      when 'date'
        warning: {
          code: 'dates',
          message: 'Dates are often easy to guess'
        }
        suggestions: [
          {
            code: 'avoid-personnal-dates-years',
            message: 'Avoid dates and years that are associated with you'
          }
        ]

  get_dictionary_match_feedback: (match, is_sole_match) ->
    warning = if match.dictionary_name == 'passwords'
      if is_sole_match and not match.l33t and not match.reversed
        if match.rank <= 10
          {
            code: 'top-10',
            message: 'This is a top-10 common password'
          }
        else if match.rank <= 100
          {
            code: 'top-100',
            message: 'This is a top-100 common password'
          }
        else
          {
            code: 'very-common',
            message: 'This is a very common password'
          }
      else if match.guesses_log10 <= 4
        {
          code: 'similar-common',
          message: 'This is similar to a commonly used password'
        }
    else if match.dictionary_name == 'english_wikipedia'
      if is_sole_match
        {
          code: 'word',
          message: 'A word by itself is easy to guess'
        }
    else if match.dictionary_name in ['surnames', 'male_names', 'female_names']
      if is_sole_match
        {
          code: 'names-surnames',
          message: 'Names and surnames by themselves are easy to guess'
        }
      else
        {
          code: 'common-names-surnames',
          message: 'Common names and surnames are easy to guess'
        }
    else
      ''

    suggestions = []
    word = match.token
    if word.match(scoring.START_UPPER)
      suggestions.push {
        code: 'capitalization',
        message: "Capitalization doesn't help very much"
      }
    else if word.match(scoring.ALL_UPPER) and word.toLowerCase() != word
      suggestions.push {
        code: 'all-uppercase',
        message: 'All-uppercase is almost as easy to guess as all-lowercase'
      }

    if match.reversed and match.token.length >= 4
      suggestions.push {
        code: 'reversed-words',
        message: "Reversed words aren't much harder to guess"
      }
    if match.l33t
      suggestions.push {
        code: 'predictable-substitutions',
        message:
          "Predictable substitutions like '@' instead of 'a' don't help very much"
      }

    result =
      warning: warning
      suggestions: suggestions
    result

module.exports = feedback
