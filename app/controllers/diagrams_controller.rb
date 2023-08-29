class DiagramsController < ApplicationController
  before_action :set_diagram, :only => [:show, :edit, :update, :destroy, :download, :share_with_institution, :share_with_only_me]
  before_action :set_diagrams, :only => [:index]

  #Enforces access right checks for individuals resources
  after_action :verify_authorized

  # Enforces access right checks for collections
  after_action :verify_policy_scoped, :only => :index

  def index
    authorize Diagram

    @categories = @diagrams.map(&:category).uniq

    #ap @diagrams.inspect


    @creators = @diagrams.map{|d|
      if d.creator.nil?
        "Creator Unknown"
      elsif d.creator.institution ==current_user.institution
        d.creator.name
      else
        d.creator.institution.name
      end
    }.uniq

    if params[:category]
      @diagrams = @diagrams.select{|d| d.category == params[:category]}
    end

    if params[:creator]

      @diagrams = @diagrams.select{|d|
        include_diagram = false

        if d.creator.institution == current_user.institution
          include_diagram = d.creator.name == params[:creator]
        else
          include_diagram = d.creator.institution.name == params[:creator]
        end

        include_diagram
      }
    end

    respond_with(@diagrams)
  end

  def show
    authorize @diagram
    respond_with(@diagram)
  end

  def new
    @diagram = Diagram.new
    2.times do
      @diagram.data_files.build
    end

    authorize @diagram

    respond_with(@diagram)
  end

  def edit
    (2 - @diagram.data_files.count).times do
      @diagram.data_files.build
    end
  end

  def create
    @diagram = Diagram.new(diagram_params)
    @diagram.institution = current_user.institution
    @diagram.creator = current_user

    authorize @diagram

    if @diagram.save
      share
      flash[:notice] = "#{controller_name.classify} successfully created."
    end



    respond_with(@diagram)
  end

  def share_with_institution
    User.where(:institution => @diagram.creator.institution).each do |user|
      unless UserDiagram.where(:user => user).where(:diagram => @diagram).exists?
        UserDiagram.new(:diagram => @diagram, :user => user).save!
      end
    end

    redirect_to :back
  end

  def share_with_only_me
    UserDiagram.where(:diagram => @diagram).each do |ud|
      if ud.user != @diagram.creator
        ud.destroy
      end
    end
    redirect_to :back
  end

  def update
    if @diagram.update_attributes(diagram_params)
      share
      #Check diagram data_format and remove data_files that don't belong to the format

      flash[:notice] = "#{controller_name.classify} successfully updated."
    end

    respond_with(@diagram)
  end

  def destroy
    @diagram.destroy
    respond_with(@diagram)
  end

  def download
    puts "#####################"
    puts params[:data_file_id]
    puts "#####################"

    redirect_to @diagram.data_files.find(params[:data_file_id].to_i).data_file.expiring_url(10), :filename => @diagram.data_files.find(params[:data_file_id].to_i).data_file.original_filename
  end

  private
    def set_diagram
      @diagram = Diagram.find(params[:id])
      authorize @diagram
    end

    def set_diagrams
      @diagrams = policy_scope(Diagram)
    end

    def share
      @diagram.users = []
      if params[:user_diagrams]
        params[:user_diagrams].each do |user_id|
          if @diagram.institution.users.map(&:id).include?(user_id.to_i)
            UserDiagram.new(:diagram_id => @diagram.id, :user_id => user_id.to_i).save!
          end
        end
      end
    end

    def diagram_params
      params.require(:diagram).permit(
        :data_format, :name, :category, :description, :downloadable, :tag_list,
        :share_with_all, :share_with_all_institutions, :creator, :local, {:data_files => []}
        #:data_files_attributes => [:id, :data_file, :name]
      )
    end
end
