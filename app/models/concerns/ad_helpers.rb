module AdHelpers
  extend ActiveSupport::Concern
  require 'mechanize'

  def entag
    @tgr ||= EngTagger.new
  end

  def synonym_finder(word)
    agent = Mechanize.new
    response = agent.get("http://words.bighugelabs.com/api/2/af2f76d4653377a25db7a69adcfa492f/#{ word }/json")
    json_synonyms = JSON.parse(response)
  end

  def random_greeting
    greetings = ["Have a good one.", "Thanks.", "Thank you.", "Hope to hear from you soon", "God bless."]
    greetings[rand(greetings.count)]
  end

  def random_compensation
    " $#{ rand(90) + 20 }/hr "
  end

  def sentence_rearranger(txt)
    if txt.present?
      sentences = txt.split(/\./)
      new_txt = ""
      arr = []

      sentences.each do |s|
        arr = assign_random_sentence_pos(arr, sentences, s)
      end
      return arr.join(".")
    else
      ""
    end
  end

  def assign_random_sentence_pos(arr, sentences, sentence)
    sentence_pos = rand(sentences.count)

    unless arr[sentence_pos].present?
      arr[sentence_pos] = sentence
    else
      arr = assign_random_sentence_pos(arr, sentences, sentence)
    end
    arr
  end

  def find_adjectives(txt)
    tagged = entag.add_tags(txt)
    entag.get_adjectives(tagged).map { |k,v| k }
  end

  def find_sims(word)
    agent = Mechanize.new
    response = agent.get("http://words.bighugelabs.com/api/2/af2f76d4653377a25db7a69adcfa492f/#{ word }/json").body
    JSON.parse(response)["adjective"]["sim"]
  end
end