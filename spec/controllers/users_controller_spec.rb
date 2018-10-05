require 'rails_helper'
require 'helpers'

RSpec.configure do |c|
  c.include Helpers
end

RSpec.describe "Routes", :type => :routing do
  it {expect(get('/admin/users')).to route_to(controller: "users", action: "index")}
  it {expect(get('/admin/users/new')).to route_to(controller: "users", action: "new")}
  it {expect(get('/admin/users/1')).to route_to(controller: "users", action: "show", id: "1")}
  it {expect(get('/admin/users/1/edit')).to route_to(controller: "users", action: "edit", id: "1")}

  it {expect(post('/admin/users')).to route_to(controller: "users", action: "create")}

  it {expect(patch('/admin/users/1')).to route_to(controller: "users", action: "update", id: "1")}

  it {expect(delete('/admin/users/1')).to route_to(controller: "users", action: "destroy", id: "1")}

end

RSpec.describe UsersController, type: :controller do
  describe 'Adding a new user' do
    
    let(:posting) {post(:create,  :params => @form_data)}
    let(:admin_test) {User.where(email: 'test@testare.se').find_first.has_role? :admin}
            
    context 'of non-admin type' do
    
      before do
        @form_data = {'user' => {:email => 'test@testare.se', :password => '1234qwerty'}}
      end
    
      it 'Adds the user to the database as a normal user' do
        expect{posting}.to change{User.count}.from(0).to(1)
        expect(admin_test).to be_falsey
      end
    end
    
    context 'of admin type' do
      
      before do
        @form_data = {'user' => {:email => 'test@testare.se', :password => '1234qwerty',  :admin => true}}
      end
      
      context 'without being logged in' do
        
        
        it 'adds the user to the database as a normal user' do
          expect{posting}.to change{User.count}.by(1)
          expect(admin_test).to be_falsey
        end
      
      end
      
      context 'with being logged in as normal user' do
        
        before do
          logged_in_user = login_test_user
        end
        
        it 'adds the user to the database as a normal user' do
          expect{posting}.to change{User.count}.by(1)
          expect(admin_test).to be_falsey
        end
      end
      
      context 'with being logged in as admin' do
        
        before do
          logged_in_user = login_test_user
          logged_in_user.add_role(:admin)
        end
        
        it 'adds the user and sets it to admin' do
          expect{posting}.to change{User.count}.by(1)
          expect(admin_test).to be_truthy
        end
        
      end
      
    end

  end

  describe 'Listing users' do
    render_views
    let(:logged_in_user) {login_test_user}
    
    before do
      create(:user,  :email => "test2@testmail.com")
      create(:user,  :email => "test3@testmail.com")
    end
    
    context 'As admin' do
    
      before do
        logged_in_user.add_role :admin
        get(:index, :format => :json)
      end
      
      it 'returns the user list' do
        expect(response).to have_http_status(:ok)
        userlist = JSON.parse(response.body).pluck("email")
        expect(userlist).to include "test2@testmail.com"
      end
    end
    
    context 'As non-admin' do
      before do
        get(:index,  :format => :json)
      end
      
      it 'responds with unauthorized' do
        expect(response).to have_http_status(:unauthorized)
      end
    end
    
    context 'When not logged in' do
      before do
        logged_in_user.add_role :admin
        sign_out(logged_in_user)
        get(:index,  :format => :json)
      end
      
      it 'responds with unauthorized' do 
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
  
  describe 'Updating user' do
    render_views
    let(:logged_in_user) {login_test_user}
    let(:other_user) {create(:user,  :email => "test2@testmail.com")}
    let(:new_mail) {"changed@mailserver.com"}
    let(:new_user_data) {{email: new_mail}}
    
    context 'as admin' do
      
      before do
        logged_in_user.add_role :admin
        patch(:update, params: {:id => other_user.attributes["_id"],  user: new_user_data})
      end
      
      it 'returns found and updates the user' do
        expect(response).to have_http_status(:found)
        expect(User.find(other_user.id).email).to eql(new_mail)
      end
    end
    
    context 'as non-admin with your own user' do
    
      before do
        patch(:update, params: {:id => logged_in_user.attributes["_id"],  user: new_user_data})
      end
      
      it 'returns found and updates the user' do
        expect(response).to have_http_status(:found)
        expect(User.find(logged_in_user.id).email).to eql(new_mail)
      end
    end
    
    context 'as non-admin with another user' do
      
      before do
        patch(:update, params: {:id => other_user.attributes["_id"],  user: new_user_data})
      end
      
      it 'returns unauthorized and does not update the user' do
        #ap controller.view_assigns
        #expect(response).to have_http_status(:unauthorized)
        expect(User.find(other_user.id).email).not_to eql(new_mail)
      end
    end
  end
  
  describe 'updating user admin status' do

    let(:logged_in_user) {login_test_user}
    let(:other_user) {create(:user,  :email => "test2@testmail.com")}
    let(:change_other) {patch(:update, params: {:id => other_user.attributes["_id"],  user: new_user_data})}
    let(:change_self) {patch(:update, params: {:id => logged_in_user.attributes["_id"],  user: new_user_data})}
    let(:admin_test) {User.where(email: other_user.email).find_first.has_role? :admin}
    let(:admin_test_self) {User.where(email: logged_in_user.email).find_first.has_role? :admin}

    context 'adding admin status' do
      let(:new_user_data) {{admin: "1"}}

      context 'as an admin' do

        before do
          logged_in_user.add_role(:admin)
        end

        context 'on another user' do
          
          before do
            change_other
          end

          it 'gives user the admin role' do
            expect(admin_test).to be_truthy
          end
        end
      end

      context 'as normal user' do

        context 'on another user' do

          before do
            change_other
          end

          it 'does not give user admin role' do
            expect(admin_test).to be_falsey
          end

        end

        context 'on self' do

          before do
            change_self
          end

          it 'does not give user admin role' do
            expect(admin_test_self).to be_falsey
          end

        end

      end

    end

    context 'removing admin status' do

      let(:new_user_data) {{admin: "0"}}

      before do
        other_user.add_role(:admin)
      end

      context 'as an admin' do

        before do
          logged_in_user.add_role :admin
        end

        context 'on another user' do
          before do
            change_other
          end

          it 'removes admin status' do
            expect(admin_test).to be_falsey
          end
        end

        context 'on self' do
          before do
            change_self
          end

          it 'does not remove admin status' do 
            expect(admin_test_self).to be_truthy
          end
        end
      end

      context 'as a normal user' do

        context 'on another user' do
          before do
            change_other
          end

          it 'does not remove admin status' do
            expect(admin_test).to be_truthy
          end

        end
      end
    end
  end
  
  describe 'deleting user' do
    render_views
    let(:logged_in_user) {login_test_user}
    let(:other_user) {create(:user,  :email => "test2@testmail.com")}
    
    context 'as admin' do
      
      before do
        logged_in_user.add_role :admin
        delete(:destroy, params: {:id => other_user.attributes["_id"]})
      end
      
      it 'returns found and deletes the user' do
        expect(response).to have_http_status(:found)
        expect(User.where(id: other_user.id)).not_to exist
      end
    end
    
    context 'as non-admin with your own user' do
    
      before do
        delete(:destroy, params: {:id => logged_in_user.attributes["_id"]})
      end
      
      it 'returns found and updates the user' do
        expect(response).to have_http_status(:found)
       expect(User.where(id: logged_in_user.id)).not_to exist
      end
    end
    
    context 'as non-admin with another user' do
      
      before do
        delete(:destroy, params: {:id => other_user.attributes["_id"]})
      end
      
      it 'returns unauthorized and does not update the user' do
        expect(User.where(id: other_user.id)).to exist
      end
    end
  end
    
end
