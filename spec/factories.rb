

FactoryBot.define do

  factory :user do
    email {"testare@testserver.com"}
    password {"qwerty12345"}
  end

  factory :game do
    name {"testspel"}
    minimum_playtime {10}
    maximum_playtime {60}
    minimum_players {1}
    maximum_players {4}
    user
  end

end
