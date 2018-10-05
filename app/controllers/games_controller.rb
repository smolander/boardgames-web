require 'open-uri'

class GamesController < ApplicationController
  before_action :set_game, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!

  def search_bgg(name)
    uri = "https://www.boardgamegeek.com/xmlapi/search?search=" + URI.encode(name)
    result = Nokogiri::HTML(open(uri))

  end

  def make_name_hash(xml_doc)
    xml_game_list = xml_doc.xpath("//boardgame")
    game_hash = Hash.new
    xml_game_list.each do |xml_game|
      name_string = xml_game.xpath("name").inner_text + " [" + xml_game.xpath("yearpublished").inner_text + "]"
      id = xml_game.attr("objectid")
      game_hash[name_string] = id
    end

    return game_hash
  end

  def get_bgg_details(id)
    uri = "https://www.boardgamegeek.com/xmlapi/boardgame/" + id
    result = Nokogiri::HTML(open(uri))
  end

  def parse_bgg_details(game_xml)
    params = Hash.new
    string_translation = {"name" => "//name[primary=true]",
                          "minimum_players" => "//minplayers",
                          "maximum_players" => "//maxplayers",
                          "minimum_playtime" => "//minplaytime",
                          "maximum_playtime" => "//maxplaytime",
                          "typical_playtime" => "//playingtime",
                          "age" => "//age"};
    string_translation.each do |para_key, xml_key|
      params[para_key] = game_xml.at_css(xml_key).inner_text
    end
    return params
  end

  def add_bgg_game(id)
    cur_game = get_bgg_details(id)
    cur_game_params = parse_bgg_details(cur_game)
    @game = Game.new(cur_game_params)
    @game.user = current_user.id
    @game.save #Add test for successful save here. Perhaps through counter.
  end

  def add_all_bgg_games(id_array)
    id_array.each do |id|
      add_bgg_game(id)
    end
  end

  def add_bgg
    id_array = params["selector"]["id"]
    add_all_bgg_games(id_array)
    redirect_to games_url
  end

  def filtered_game_list(filter_params)
    @games = @games.where(:age.lte => filter_params["age"]) if (filter_params["age"] != "" && filter_params["age"] != nil)
    @games = @games.where(:maximum_playtime.lte => filter_params["play_time_max"]) if (filter_params["play_time_max"] != "" && filter_params["play_time_max"] != nil)
    @games = @games.where(:minimum_playtime.gte => filter_params["play_time_min"]) if (filter_params["play_time_min"] != "" && filter_params["play_time_min"] != nil)
    @games = @games.where(:minimum_players.lte => filter_params["num_play"]) if (filter_params["num_play"] != "" && filter_params["num_play"] != nil)
    @games = @games.where(:maximum_players.gte => filter_params["num_play"]) if (filter_params["num_play"] != "" && filter_params["num_play"] != nil)
    return @games

  end

  # GET /games
  # GET /games.json
  def index
    @games = Game.all
    @games = @games.where(:user => current_user)
    if params["commit"] == "Filter"
      @games = filtered_game_list(params)
    end
  end

  # GET /games/1
  # GET /games/1.json
  def show
  end

  # GET /games/new
  def new
    @game = Game.new

    if params["search"]
      @name = params["search"]["bgg_search"]
      @bgg_xml = search_bgg(@name)
      @bgg_hash = make_name_hash(@bgg_xml)
    end

    render :new
  end

  # GET /games/1/edit
  def edit
  end

  # POST /games
  # POST /games.json
  def create
    @game = Game.new(game_params)
    @game.user = current_user
    respond_to do |format|
      if @game.save
        format.html { redirect_to @game, notice: 'Game was successfully created.' }
        format.json { render :show, status: :created, location: @game }
      else
        format.html { render :new }
        format.json { render json: @game.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /games/1
  # PATCH/PUT /games/1.json
  def update
    if @game.user == current_user
      updated = @game.update(game_params)
      @notice = "Game was sucessfully updated."
    else
      @notice = "Game not updated since it belongs to another user."
    end
    respond_to do |format|
      if updated
        format.html { redirect_to @game, notice: @notice }
        format.json { render :show, status: :ok, location: @game }
      else
        format.html { render :edit }
        format.json { render json: @game.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /games/1
  # DELETE /games/1.json
  def destroy
    if @game.user == current_user
      @game.destroy
      @notice = 'Game was successfully destroyed.'
    else
      @notice = 'Game not deleted since it belongs to another user.'
    end
    respond_to do |format|
      format.html { redirect_to games_url, notice: @notice }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_game
      if Game.where(id: params[:id]).exists?
        @game = Game.find(params[:id])
      else
        @game = Game.new
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def game_params
      params.require(:game).permit(:name, :minimum_players, :maximum_players, :minimum_playtime, :maximum_playtime, :typical_playtime, :age, :categories)
    end
end
