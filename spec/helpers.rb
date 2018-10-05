module Helpers
  def login_test_user(email = "test@testmail.com")
    test_user = create(:user, email: email)
    sign_in(test_user)
    return test_user
  end

  def add_test_game(user, id="")
    #test_game = Game.new(name: "testspel#{id}", user: user, minimum_playtime: 10, maximum_playtime: 60, minimum_players: 1, maximum_players: 4)
    #test_game.save!
    test_game = create(:game, user: user)
    return test_game
  end
end