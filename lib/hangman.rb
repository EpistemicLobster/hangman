require 'pry-byebug'
require 'yaml'

module Drawings
  SIX_EMPTY = "⸻\n|   | \n|   ╽\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|______".freeze
  FIVE_HEAD =  "⸻\n|   | \n|   ╽\n|  ---\n| |   |\n|  ---\n|\n|\n|\n|\n|\n|\n|\n|______".freeze
  FOUR_BODY =  "⸻\n|   | \n|   ╽\n|  ---\n| |   |\n|  ---\n|   |\n" \
               "|   |   \n|   |   \n|   |\n|      \n|       \n|\n|______".freeze
  THREE_ARM = "⸻\n|   | \n|   ╽\n|  ---\n| |   |\n|  ---\n|   |\n" \
              "|  /|   \n| / |   \n|   |\n|      \n|       \n|\n|______".freeze
  TWO_ARMS = "⸻\n|   | \n|   ╽\n|  ---\n| |   |\n|  ---\n|   |\n" \
             "|  /|\\ \n| / | \\\n|   |\n|      \n|       \n|\n|______".freeze
  ONE_LEG = "⸻\n|   | \n|   ╽\n|  ---\n| |   |\n|  ---\n|   |\n" \
            "|  /|\\ \n| / | \\\n|   |\n|  /   \n| /     \n|\n|______".freeze
  ZERO_LEGS = "⸻\n|   | \n|   ╽\n|  ---\n| |   |\n|  ---\n|   |\n" \
              "|  /|\\ \n| / | \\\n|   |\n|  / \\\n| /   \\\n|\n|______".freeze
end

class Word
  def initialize
    @word = fetch_word
  end

  attr_accessor :word

  def fetch_word
    words = File.readlines('google_10000_english.txt')
    array = []
    words.each do |line|
      array.push(line) if line.length > 5 && line.length < 12
    end
    array.sample
  end
end


class Player
  def initialize(player)
    @player = player
    @guess = ''
    @guesses = []
  end

  attr_accessor :guess, :guesses
end

class Game
  include Drawings

  def initialize
    @player = Player.new('player')
    @hidden = Word.new.word.chomp.split('')
    @guesses_remaining = 6
    @board = Array.new(hidden.length, '_')
    @win_state = false
  end

  attr_reader :hidden, :board
  attr_accessor :player, :guesses_remaining, :guesses, :win_state

  def show_board
    puts " \nWord: \n "
    puts board.join(' ')
    puts "\nGuesses: #{player.guesses.join(' | ')}\n "
    puts "Guesses Remaining: #{guesses_remaining}\n "
    hangman
    puts "Please make a guess by entering a letter. Or enter 'save' to save the game."
    check_win
  end

  def hangman
    case guesses_remaining
    when 6
      puts SIX_EMPTY
    when 5
      puts FIVE_HEAD
    when 4
      puts FOUR_BODY
    when 3
      puts THREE_ARM
    when 2
      puts TWO_ARMS
    when 1
      puts ONE_LEG
    when 0
      puts ZERO_LEGS
    end
  end

  def make_guess
    @player.guess = gets.chomp.downcase
    @player.guess == 'save' ? save_game : @player.guess
    if @player.guess == 'exit'
       @guesses_remaining = 0
    elsif @player.guess == 'continue'
      puts 'Please make a guess by entering a letter: '
      @player.guess = gets.chomp.downcase
      invalid_entry
    else
      invalid_entry
    end
  end

  def invalid_entry
    while player.guess.match?(/[^a-zA-Z]/) || player.guess.length > 1
      puts "Invalid Entry - Please try again: "
      @player.guess = gets.chomp.downcase
    end
    while player.guesses.include?(player.guess)
      puts "You've already guessed that letter! Try again: "
      @player.guess = gets.chomp.downcase
    end
    @player.guesses.push(player.guess)
  end

  def exit
    @guesses_remaining = 0
  end

  def evaluate_guess
    letters = {}
    player.guess.split('').each do |e|
      if hidden.include?(e)
        letters[e] = hidden.each_index.select { |l| hidden[l] == e }
      end
    end
    letters.empty? ? @guesses_remaining -= 1 : array_letters(letters)
  end

  def array_letters(hash)
    hash.each_pair do |k, v|
      v.each { |i| @board[i] = k}
    end
    check_win
  end

  def check_win
    if board.none?('_')
      @guesses_remaining = 0
      @win_state = true
    end
  end

  def save_game
    File.open('saved.yaml', 'w') { |file| file.puts YAML::dump(self) }
    puts 'You\'ve successfully saved the game!'
    puts 'Please enter exit or continue: '
    @player.guess = gets.chomp.downcase
  end
end

class Play
  def self.game
    game = saved_or_new
    game.show_board
    while game.guesses_remaining > 0 
      game.make_guess
      game.evaluate_guess
      game.show_board
    end
    win_status(game.player.guess, game.win_state, game.hidden)
  end

  def self.saved_or_new
    puts 'Would you like to load a saved game?'
    puts "Input 'Y' to load game, or 'N' to start a new game: "
    gets.chomp.downcase == 'y' ? load_saved : Game.new
  end

  def self.load_saved
    File.open('saved.yaml', 'r') { |obj| YAML::load(obj) }
  end

  def self.win_status(player_guess, win_state, hidden)
    if player_guess == 'exit'
      puts "You've successfully exited the game. See you again soon! =) "
    else
      win_state == true ? game_won : game_lost(hidden.join(' '))
    end
  end

  def self.game_won
    puts "\nCongratulations!\n "
    sleep 0.2
    puts 'YOU'
    sleep 0.2
    puts "WIN\n "
  end

  def self.game_lost(secret_word)
    puts "\nSorry! You Lost!\n "
    sleep 0.2
    puts "The secret word was  '#{secret_word}'.\n "
  end
end

Play.game