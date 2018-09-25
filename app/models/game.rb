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
  belongs_to :user

  validates_presence_of(:name)
  validates :name, :uniqueness => {:scope=>:user}
  validates_presence_of(:user)
  validates_numericality_of :minimum_players, greater_than: 0
  validates_numericality_of :maximum_players, greater_than_or_equal_to: :minimum_players
  validates_numericality_of :minimum_playtime, greater_than_or_equal_to: 0
  validates_numericality_of :maximum_playtime, greater_than_or_equal_to: :minimum_playtime
  validates_numericality_of :typical_playtime, less_than_or_equal_to: :maximum_playtime, greater_than_or_equal_to: :minimum_playtime, allow_nil: true
  validates_numericality_of :age, greater_than_or_equal_to: 0, allow_nil: true
end
