require "application_system_test_case"

class GamesTest < ApplicationSystemTestCase
  setup do
    @game = games(:one)
  end

  test "visiting the index" do
    visit games_url
    assert_selector "h1", text: "Games"
  end

  test "creating a Game" do
    visit games_url
    click_on "New Game"

    fill_in "Age", with: @game.age
    fill_in "Categories", with: @game.categories
    fill_in "Maximum Players", with: @game.maximum_players
    fill_in "Maximum Playtime", with: @game.maximum_playtime
    fill_in "Minimum Players", with: @game.minimum_players
    fill_in "Minimum Playtime", with: @game.minimum_playtime
    fill_in "Name", with: @game.name
    fill_in "Typical Playtime", with: @game.typical_playtime
    click_on "Create Game"

    assert_text "Game was successfully created"
    click_on "Back"
  end

  test "updating a Game" do
    visit games_url
    click_on "Edit", match: :first

    fill_in "Age", with: @game.age
    fill_in "Categories", with: @game.categories
    fill_in "Maximum Players", with: @game.maximum_players
    fill_in "Maximum Playtime", with: @game.maximum_playtime
    fill_in "Minimum Players", with: @game.minimum_players
    fill_in "Minimum Playtime", with: @game.minimum_playtime
    fill_in "Name", with: @game.name
    fill_in "Typical Playtime", with: @game.typical_playtime
    click_on "Update Game"

    assert_text "Game was successfully updated"
    click_on "Back"
  end

  test "destroying a Game" do
    visit games_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Game was successfully destroyed"
  end
end
