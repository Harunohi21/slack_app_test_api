class UserManageController < ApplicationController
  def update 
    m_users = MUser.find_by(id: params[:id])
    
    if m_users
      if m_users.member_status == false
        @m_us = MUser.where(id: params[:id]).update_all(member_status: true)
      else
        @m_us = MUser.where(id: params[:id]).update_all(member_status: false)
      end
      usermanage
      render json: m_users, status: :ok
    else  
      render json: { error: 'User not found' }, status: :not_found
    end
  end

  def usermanage
    @m_user = MUser.find_by(id: @current_user)
    @user_manages_activate = MUser.select("m_users.id, name, email, member_status, admin, m_users_profile_images.image_url")
                                  .joins("JOIN t_user_workspaces ON t_user_workspaces.id = m_users.id
                                  LEFT JOIN m_users_profile_images ON m_users_profile_images.m_user_id = m_users.id")
                                  .where("t_user_workspaces.id = m_users.id AND admin <> true AND member_status = true AND t_user_workspaces.workspaceid = ?", @current_user)

    @user_manages_deactivate = MUser.select("m_users.id, name, email, member_status, admin")
                                    .joins("JOIN t_user_workspaces ON t_user_workspaces.id = m_users.id")
                                    .where("t_user_workspaces.id = m_users.id AND admin <> true AND member_status = false AND t_user_workspaces.workspaceid = ?", @current_user)

    @user_manages_admin = MUser.select("m_users.id, name, email, member_status, admin, m_users_profile_images.image_url")
                                    .joins("JOIN t_user_workspaces ON t_user_workspaces.id = m_users.id")
                                    .joins("LEFT JOIN m_users_profile_images ON m_users_profile_images.m_user_id = m_users.id")
                                    .where("t_user_workspaces.id = m_users.id AND m_users.admin = true AND t_user_workspaces.workspaceid = ?", @current_user)

    @m_userer = MUser.select("m_users.id, m_users.name, m_users.email, m_users.password_digest, m_users.profile_image, m_users.remember_digest, m_users.active_status, m_users.admin, m_users.member_status, m_users.created_at, m_users.updated_at, m_users_profile_images.image_url")
                            .joins("LEFT JOIN m_users_profile_images ON m_users_profile_images.m_user_id = m_users.id
                            INNER JOIN t_user_workspaces ON t_user_workspaces.userid = m_users.id
                            INNER JOIN m_workspaces ON m_workspaces.id = t_user_workspaces.workspaceid")
                            .where("m_users.member_status = false OR m_users.member_status = true AND m_workspaces.id = ?", @current_workspace)

    retrievehome
  end
end
