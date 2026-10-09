# Reference implementation for test/sakelib/highline.rb: a subset of the highline gem (2.x) in plain
# Ruby (the gem is not installed here), from memory of its QuestionAsker / Question / Menu:
# say (print when the statement ends with a space, else puts), ask with a type (Integer, Float), a
# default (appended as |default|), validate (a Regexp), in/above/below ranges, the error responses and
# the "?  " re-prompt, agree (yes/no, re-asks the question), choose (numbered list, by number or by a
# unique prefix of a name), list and newline.

class HighLine
  class Question
    attr_accessor :question, :answer_type, :default, :validate, :in, :above, :below, :responses, :answer

    def initialize(question, answer_type)
      @question = question
      @answer_type = answer_type
      @responses = {
        ask_on_error: "?  ",
        invalid_type: "You must enter a valid #{answer_type}.",
        not_valid: nil, # built when validate is known
        not_in_range: nil,
      }
    end

    def text
      return question unless default
      if question =~ /([\t ]+)\Z/
        "#{question}|#{default}|#{$1}"
      elsif question == ""
        "|#{default}|  "
      elsif question[-1, 1] == "\n"
        "#{question[0..-2]}  |#{default}|\n"
      else
        "#{question}  |#{default}|"
      end
    end

    def response(key)
      responses[key] || case key
                        when :not_valid then "Your answer isn't valid (must match #{validate.inspect})."
                        when :not_in_range then "Your answer isn't within the expected range (#{expected_range})."
                        end
    end

    def expected_range
      expected = []
      expected << "above #{above}" if above
      expected << "below #{below}" if below
      expected << "included in #{self.in.inspect}" if self.in
      expected.join(" and ")
    end

    def valid_answer?(s) = validate.nil? || s =~ validate

    def convert(s)
      if answer_type.nil? then s
      elsif answer_type == Integer then Integer(s)
      elsif answer_type == Float then Float(s)
      elsif answer_type.is_a?(Array) then complete(s)
      else answer_type.call(s)
      end
    end

    def complete(s)
      exact = answer_type.find { |c| c.to_s == s }
      return exact if exact
      candidates = answer_type.select { |c| c.to_s.downcase.start_with?(s.downcase) }
      raise ArgumentError, "ambiguous choice" if candidates.size > 1
      raise ArgumentError, "invalid value for choice" if candidates.empty?
      candidates.first
    end

    def in_range?(v)
      (above.nil? || v > above) && (below.nil? || v < below) && (self.in.nil? || self.in.include?(v))
    end

    def ask_on_error_msg = responses[:ask_on_error] == :question ? text : responses[:ask_on_error]
  end

  attr_reader :input, :output

  def initialize(input = $stdin, output = $stdout)
    @input = input
    @output = output
  end

  def say(statement)
    statement = statement.to_s
    if statement[-1, 1] == " " || statement[-1, 1] == "\t"
      output.print statement
      output.flush
    else
      output.puts statement
    end
  end

  def newline = output.puts

  def list(items, mode = :rows)
    raise ArgumentError, "unsupported list mode #{mode.inspect}" unless mode == :rows
    items.map { |i| "#{i}\n" }.join
  end

  def get_line
    line = input.gets
    raise EOFError, "The input stream is exhausted." unless line
    line.chomp
  end

  def ask(question, answer_type = nil)
    q = question.is_a?(Question) ? question : Question.new(question, answer_type)
    yield q if block_given?
    say(q.text)
    loop do
      answer = get_line.strip
      answer = q.default.to_s if answer.empty? && q.default
      begin
        raise ExplainableError, :not_valid unless q.valid_answer?(answer)
        value = q.convert(answer)
        raise ExplainableError, :not_in_range unless q.in_range?(value)
        return value
      rescue ExplainableError => e
        explain_error(q, e.message.to_sym)
      rescue ArgumentError => e
        case e.message
        when /ambiguous/ then explain_error(q, :ambiguous_completion)
        when /invalid value for/ then explain_error(q, :invalid_type)
        else raise
        end
      end
    end
  end

  class ExplainableError < StandardError; end

  def explain_error(q, key)
    say(q.response(key))
    say(q.ask_on_error_msg)
  end

  def agree(yes_or_no_question, character = nil)
    ask(yes_or_no_question, ->(yn) { yn.downcase[0] == "y" }) do |q|
      q.validate = /\A(?:y(?:es)?|no?)\Z/i
      q.responses[:not_valid] = 'Please enter "yes" or "no".'
      q.responses[:ask_on_error] = :question
      yield q if block_given?
    end
  end

  # The gem's Menu with its defaults (index :number, suffix ". ", select by index or name, prompt
  # "?  ", layout :list), configured by the block as the gem's; returns the chosen item.
  class Menu
    attr_accessor :header, :prompt, :items

    def initialize
      @items = []
      @prompt = "?  "
    end

    def choice(name) = @items << name
    def choices(*names) = @items.concat(names)
  end

  def choose(*items)
    menu = Menu.new
    menu.choices(*items)
    yield menu if block_given?
    items = menu.items
    names = items.map(&:to_s)
    indexes = (1..items.size).map(&:to_s)
    text = (menu.header ? "#{menu.header}:\n" : "") +
           list(items.each_with_index.map { |item, i| "#{i + 1}. #{item}" }) + menu.prompt
    q = Question.new(text, indexes + names)
    q.responses[:invalid_type] = "You must choose one of #{choices_complete_list(indexes + names)}."
    q.responses[:ambiguous_completion] = "Ambiguous choice.  Please choose one of #{choices_complete_list(indexes + names)}."
    chosen = ask(q)
    i = indexes.index(chosen)
    i ? items[i] : items[names.index(chosen)]
  end

  def choices_complete_list(choices) = "[#{choices.join(', ')}]"
end
