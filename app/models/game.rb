class Game
  include Mongoid::Document
  resourcify
  field :name, type: String
  field :minimum_players, type: Integer
  field :maximum_players, type: Integer
  field :minimum_playtime, type: Integer
  field :maximum_playtime, type: Integer
  field :typical_playtime, type: Integer
  field :age, type: Integer
  #field :categories, type: Array
  field :user, type: String
end
