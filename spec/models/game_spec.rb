require 'rails_helper'

def login_test_user(id = "")
  test_user = User.new(email: "test#{id}@test.com", password: "test@123")
  test_user.save!
  sign_in(test_user)
  return test_user
end

def add_test_game(id="")
  test_game = Game.new(name: "testgame#{id}")
end

RSpec.describe Game, type: :model do
  it {is_expected.to validate_presence_of :name}
  it {is_expected.to validate_uniqueness_of(:name).scoped_to(:user)}
  it {is_expected.to validate_presence_of :user}
  it {is_expected.to validate_numericality_of(:minimum_players).greater_than(0)}
  it {is_expected.to validate_numericality_of(:maximum_players).greater_than_or_equal_to(:minimum_players)}
  it {is_expected.to validate_numericality_of(:minimum_playtime).greater_than_or_equal_to(0)}
  it {is_expected.to validate_numericality_of(:maximum_playtime).greater_than_or_equal_to(:minimum_playtime)}
  it {is_expected.to validate_numericality_of(:typical_playtime).allow_nil(true).greater_than_or_equal_to(:minimum_playtime)}
  it {is_expected.to validate_numericality_of(:typical_playtime).allow_nil(true).less_than_or_equal_to(:maximum_playtime)}
  it {is_expected.to validate_numericality_of(:age).allow_nil(true).greater_than_or_equal_to(0)}

  it {is_expected.to belong_to (:user)}

end
