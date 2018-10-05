require 'rails_helper'
require 'helpers'

RSpec.configure do |c|
  c.include Helpers
end

RSpec.describe "Routes", :type => :routing do
  it {expect(get('/games')).to route_to(controller: "games", action: "index")}
  it {expect(get('/games/new')).to route_to(controller: "games", action: "new")}
  it {expect(get('/games/1')).to route_to(controller: "games", action: "show", id: "1")}
  it {expect(get('/games/1/edit')).to route_to(controller: "games", action: "edit", id: "1")}

  it {expect(post('/games/add_bgg')).to route_to(controller: "games", action: "add_bgg")}
  it {expect(post('/games')).to route_to(controller: "games", action: "create")}

  it {expect(patch('/games/1')).to route_to(controller: "games", action: "update", id:"1")}

  it {expect(delete('/games/1')).to route_to(controller: "games", action: "destroy", id:"1")}


end

RSpec.shared_examples 'login_required_page' do |page, game_id|

  context 'when not logged in' do
    before do
      if game_id
        get page, params: {id: game_id}
      else
        get page
      end
    end

    it 'returns a redirect to login page' do
      expect(response).to have_http_status(:redirect)
      expect(response.location).to include('users/sign_in')
    end
  end

  context 'when logged in' do
    before do
      login_test_user
      if game_id
        get page, params: {id: game_id}
      else
        get page
      end
    end

    it 'returns http ok' do
      expect(response).to have_http_status(:ok)
    end
  end
end

RSpec.shared_examples 'not changing database' do |model, status=:ok|
  it 'returns appropriate response' do
    expect(response).to have_http_status(status)
  end
  it 'does not add the game to the database' do
    expect(model.count).to eql(@before_count)
  end
end

RSpec.describe GamesController, type: :controller do



  describe 'GET' do

    context 'index page' do
      it_behaves_like 'login_required_page', :index
    end
    context 'new page' do
      it_behaves_like 'login_required_page', :new
    end
    context 'show page' do
      it_behaves_like 'login_required_page', :show, 1
    end
    context 'edit page' do
      it_behaves_like 'login_required_page', :edit, 1
    end
  end
  
  describe 'Listing the games' do
    render_views
    before do
      
      test_user = login_test_user
      create(:game, user: test_user)
      test_user_2 = login_test_user("tester2@serv.com")
      create(:game,  name: "testspel 2",  user: test_user_2,  minimum_players: 4,  maximum_players: 8)
      create(:game,  name: "testspel 3",  user: test_user_2)
    end
    
    context 'without filter' do
      before do
        get(:index,  :format => :json)
      end
    
      it 'lists the games for the user, but not for other users' do
        name_list = JSON.parse(response.body).pluck("name")
        expect(name_list).not_to include("testspel")
        expect(name_list).to include("testspel 2")
        expect(name_list).to include("testspel 3")
      end
    end
  
    context 'with filtering on number of players' do
      before do
        get(:index,  :format => :json,  :params => {:commit => "Filter", :num_play => 3})
      end
      
      it 'lists the game for the user that is also consistent with the filter' do
        name_list = JSON.parse(response.body).pluck("name")
        expect(name_list).not_to include("testspel")
        expect(name_list).not_to include("testspel 2")
        expect(name_list).to include("testspel 3")
      end
    end
  end

  describe 'Adding a new game' do

    context 'Without being logged in' do
      before do
        @before_count = Game.count
        post :create

      end
      it_behaves_like 'not changing database', Game, :redirect
    end

    context 'Manually with everything correct' do

      before do
        @before_count = Game.count
        @cur_user = login_test_user
        form_data = {'game' => {:name => 'testspel', :minimum_players => 1, :maximum_players => 4, :minimum_playtime => 10, :maximum_playtime => 60}}

        post(:create, :params => form_data)
      end
      it 'redirects to the appropriate page' do
        expect(response).to have_http_status(:redirect)
        game_id = response.location.split("/")[-1]
        db_post = Game.find_by(name: 'testspel')
        expect(db_post.id.to_s).to eq(game_id)
      end
      it 'adds the game to the database under the current user' do
        expect(Game.count).to eq(@before_count + 1)
        db_post = Game.find_by(name: 'testspel')
        expect(db_post.user).to eq(@cur_user)
      end
    end

    context 'Manually, but without game name' do
      before do
        @before_count = Game.count
        login_test_user
        form_data = {'game' => {:minimum_players => 1, :maximum_players => 4, :minimum_playtime => 10, :maximum_playtime => 60}}
        post(:create, :params => form_data)
      end

      it_behaves_like 'not changing database', Game
    end

    context 'Manually but game exists ' do

      before do
        @cur_user = login_test_user
        add_test_game(@cur_user)
        @before_count = Game.count

      end
      context 'For this user' do

        before do
          form_data = {'game' => {:name => 'testspel', :minimum_players => 1, :maximum_players => 4, :minimum_playtime => 10, :maximum_playtime => 60}}
          post(:create, :params => form_data)
        end

        it_behaves_like 'not changing database', Game
        
      end
      context 'For another user' do
        before do
          @cur_user = login_test_user("2@3.com")
          form_data = {'game' => {:name => 'testspel', :minimum_players => 1, :maximum_players => 4, :minimum_playtime => 10, :maximum_playtime => 60}}
          post(:create, :params => form_data)
        end

        it 'redirects to the appropriate page' do
          expect(response).to have_http_status(:redirect)
          game_id = response.location.split("/")[-1]
          db_post = Game.find_by(name: 'testspel', user: @cur_user)
          expect(db_post.id.to_s).to eq(game_id)
        end
        it 'adds the game to the database under the current user' do
          expect(Game.count).to eq(@before_count + 1)
          db_post = Game.find_by(name: 'testspel', user: @cur_user)
          expect(db_post.user).to eq(@cur_user)
        end
      end

    end

    context 'Internal methods for getting details from BGG' do

      let(:search_term) {"power grid"}
      let(:search_list) {controller.search_bgg(search_term)}
      let(:name_hash) {controller.make_name_hash(search_list)}
      let(:detailed_search) {controller.get_bgg_details(name_hash.first[1])}
      let(:parsed_details) {controller.parse_bgg_details(detailed_search)}

      before do

      end

      it 'fetches a non-empty document from BGG when searching' do
        expect(search_list.inner_html).not_to eql("")
      end
      it 'translates the BGG document to a name hash' do
        expect(name_hash.blank?).to be_falsey
      end

      it 'fetches a non-empty document from BGG when getting details' do
        expect(detailed_search).not_to eql("")
      end

      it 'parses the BGG details' do
         expect(parsed_details.blank?).to be_falsey
      end

    end

    context 'API endpoints for getting game info from BGG' do

      let(:search_term) {"settlers"}

      context 'Getting a full list' do

        before do
          @cur_user = login_test_user
          get(:new, params: {:search => {:bgg_search => search_term}})
        end

        it 'returns status OK' do
          expect(response).to have_http_status(:ok)
        end

        it 'generates a list' do
          expect(controller.view_assigns['bgg_hash']).not_to be_nil
        end
      end

      context 'Gets game details' do

        let(:id_list) do
          search_doc = controller.search_bgg(search_term)
          name_hash = controller.make_name_hash(search_doc)
          return name_hash.values[2,5]
        end

        before do
          @cur_user = login_test_user
          @before_count = Game.count
          post(:add_bgg, params: {selector: {id: id_list}})
        end

        it 'returns status OK' do
          expect(response).to have_http_status(:found)
        end

        it 'sets appropriate variables' do
          expect(controller.view_assigns["game"]).not_to be_nil
        end

        it 'adds games to the database' do
          expect(Game.count).to eql(@before_count + id_list.length)
        end
      end
    end
  end

  describe 'Calling the remove function' do

    context 'without being logged in' do
      before do
        test_user = login_test_user
        testgame = add_test_game(test_user)
        @before_count = Game.count
        sign_out(test_user)
        delete(:destroy, params: {:id => testgame.attributes["_id"]})

      end

      it_behaves_like 'not changing database', Game, :found

    end

    context 'with being logged in, but not the owner of the game' do

      before do
        test_user = login_test_user
        testgame = add_test_game(test_user)
        @before_count = Game.count
        sign_out(test_user)
        another_user = login_test_user("testare_2@mail.com")
        delete(:destroy, params: {:id => testgame.attributes["_id"]})

      end


      it 'informs that the game belongs to the wrong user' do
        expect(controller.view_assigns["notice"]).to eql("Game not deleted since it belongs to another user.")
      end
      it_behaves_like  "not changing database", Game, :found
    end


    context 'with being logged in as the owner of the game' do

      before do
        test_user = login_test_user
        testgame = add_test_game(test_user)
        @before_count = Game.count
        delete(:destroy, params: {:id => testgame.attributes["_id"]})
      end

      it 'deletes the game from the db' do 
        expect(Game.count).to eq(@before_count - 1)
      end
      it 'redirects to the appropriate page' do
        hostname = response.request.env["HTTP_HOST"]
        redirect_location = response["Location"]
        expect(redirect_location).to eql("http://"+hostname+"/games")
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe 'calling the update function' do

    let(:new_game_data) {{name: "test_2"}}#, minimum_players: 3, maximum_players: 7, minimum_playtime: 32, maximum_playtime: 107, typical_playtime: 96, age: 12}}
    let(:test_user) { login_test_user}
    let(:testgame) {add_test_game(test_user)}

    context 'without being logged in' do
      before do
        sign_out(test_user)
        patch(:update, params: {:id => testgame.attributes["_id"], :game => new_game_data})
      end

      it 'does not update the game' do
        expect(testgame).to eql(Game.find(testgame.id))
      end

    end

    context 'with being logged in, but not the owner of the game' do

      before do
        sign_out(test_user)
        login_test_user("test2@mail.com")
        patch(:update, params: {:id => testgame.attributes["_id"], :game => new_game_data})

      end


      it 'informs that the game belongs to the wrong user' do
        expect(controller.view_assigns["notice"]).to eql("Game not updated since it belongs to another user.")
      end

      it 'does not update the game' do
        expect(testgame.name).to eql(Game.find(testgame.id).name)
      end
    end


    context 'with being logged in as the owner of the game' do

      before do
        patch(:update, params: {:id => testgame.attributes["_id"], :game => new_game_data})
      end

      it 'updates the game' do
        expect(testgame.name).not_to eq(Game.find(testgame.id).name)
      end
    end
  end
end
