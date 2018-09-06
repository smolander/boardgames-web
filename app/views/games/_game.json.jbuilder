json.extract! game, :id, :name, :minimum_players, :maximum_players, :minimum_playtime, :maximum_playtime, :typical_playtime, :age, :categories, :created_at, :updated_at
json.url game_url(game, format: :json)
