class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable

  royce_roles %w[
    institution-admin

    user-view
    user-update
    user-set-roles
    user-approve
    user-destroy

    diagram-create
    diagram-update
    diagram-destroy
    diagram-download
  ]


  belongs_to :institution

  validates_presence_of :institution
  validates_presence_of :name, :title, :department

  has_many :user_diagrams, :dependent => :delete_all
  has_many :diagrams, :through => :user_diagrams

  has_many :authored_diagrams, :class_name => "Diagram", :foreign_key => :creator_id

  after_create :send_admin_mail

  def send_admin_mail
    AdminMailer.new_user_waiting_for_approval(self).deliver
  end

  def active_for_authentication?
    super && approved?
  end

  def inactive_message
    if !approved?
      :not_approved
    else
      super # Use whatever other message
    end
  end

  def role_dependencies
    {
        "user-update" => "user-view",
        "user-destroy" => "user-view",
        "user-approve" => "user-update",
        "user-set-roles" => "user-update",
        "diagram-update" => "diagram-create",
        "diagram-destroy" => "diagram-create"
    }
  end

  def dependent_roles
    {
        "user-view" => %w(user-update user-destroy user-approve user-set-roles),
        "user-update" => %w(user-approve user-set-roles),
        "diagram-create" => %w(diagram-update diagram-destroy)
    }
  end

end
