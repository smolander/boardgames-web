class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!,  except: [:create]
  load_and_authorize_resource except: [:create]

  # GET /users
  # GET /users.json
  def index
    ap "Getting index!"
    @users = User.all
  end

  # GET /users/1
  # GET /users/1.json
  def show
    ap "Or does it go here?"
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users
  # POST /users.json
  def create
    ap "Is this where it goes?"
    @user = User.new(user_params)
    if request.parameters["user"]["admin"] && user_signed_in? && current_user.has_role?(:admin)
      @user.add_role(:admin)
    end

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'User was successfully created.' }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    ap "Patching!"
    if params["user"]["admin"].present? && current_user.has_role?(:admin)
      if params["user"]["admin"] == "1"
        @user.add_role(:admin)
      elsif @user != current_user
        @user.remove_role(:admin)
      end
    end
    respond_to do |format|
      if @user.update(user_params)
        
        ap "User update worked!"
        #@notice = 'User was successfully updated.'
        format.html { redirect_to :users, notice: "User #{user_params[:email]} was successfully updated." }
        format.json { render :show, status: :ok, location: @user }
      else
        ap "User update did not work!"
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url, notice: 'User was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.fetch(:user, {})
      params.require(:user).permit(:email, :password, :admin)
    end

end
