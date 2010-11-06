# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008-2010 TIS Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

module SystemMessagesHelper
  def system_message_links
    return @system_message_links if @system_message_links
    system_message_links = []

    if system_notice = SkipEmbedded::InitialSettings['system_notice'] and !system_notice['title'].blank?
      system_message_links << link_to(icon_tag('information') + h(system_notice['title']), system_notice['url'])
    end

    if enable_enquete?
      system_message_links << link_to(icon_tag('information') + 'SKIPのご利用ありがとうございます。品質向上のためのアンケートを実施しています。この機会に皆様の声をぜひお聞かせください。ご協力お願いします。 ', 'https://spreadsheets.google.com/viewform?formkey=dHprYkFZODlOYnVlRVo5OS1sYzhYWlE6MA', :id => 'enquete_link')
    end

    if Admin::Setting.enable_password_periodic_change && !current_user.password_expires_at.blank? && current_user.password_expires_at.ago(2.week) < Time.now
      system_message_links << link_to(icon_tag('bullet_error') + _('The password expiration date (%s) approaches') % current_user.password_expires_at.ago(1.day).strftime(_('%B %d %Y')), url_for(:controller => 'mypage', :action => 'manage', :menu => 'manage_password'))
    end

    unless current_user.picture
      system_message_links << link_to(icon_tag('picture') + _("Change your profile picture!"), {:controller => "mypage", :action => "manage", :menu => "manage_portrait"})
    end

    current_user.system_messages.each do |sm|
      system_message_data = system_message_data(sm)
      system_message_links << link_to(icon_tag(system_message_data[:icon]) + system_message_data[:message], system_message_data[:url]) + "(#{link_to 'x', user_system_message_path(current_user, sm), :class => 'delete_system_message'})" unless system_message_data.blank?
    end

    Group.active.has_waiting_for_approval.id_equals(Group.active.owned(current_user).map(&:id)).each do |group|
      system_message_links << link_to(icon_tag('group_add') + _("New user is waiting for approval in %s.") % group.name, {:controller => 'group', :action => 'manage', :gid => group.gid, :menu => 'manage_permit'})
    end
    @system_message_links = system_message_links
  end

  def system_message_data message, target_user = current_user
    return nil if message.blank?
    case message.message_type
      when 'COMMENT'
        board_entry = BoardEntry.accessible(target_user).find(message.message_hash[:board_entry_id])
        {
          :message => _("You recieved a comment on your entry [%s]!") % board_entry.title,
          :icon => 'comments',
          :url => url_for(board_entry.get_url_hash.merge!(:system_message_id => message.id))
        }
      when 'TRACKBACK'
        board_entry = BoardEntry.accessible(target_user).find(message.message_hash[:board_entry_id])
        {
          :message => _("There is a new entry talking about your entry [%s]!") % board_entry.title,
          :icon => 'report_go',
          :url => url_for(board_entry.get_url_hash.merge!(:system_message_id => message.id))
        }
      when 'CHAIN'
        user = User.find(message.message_hash[:user_id])
        {
          :message => _("You received an introduction!"),
          :icon => 'user_comment',
          :url => url_for({:controller => 'user', :uid => user.uid, :action => 'social', :menu => 'social_chain', :system_message_id => message.id})
        }
      when 'QUESTION'
        board_entry = BoardEntry.accessible(target_user).question.find(message.message_hash[:board_entry_id])
        {
          :message => _('State of your question [%s] is changed!') % board_entry.title,
          :icon => 'tick',
          :url => url_for(board_entry.get_url_hash.merge!(:system_message_id => message.id))
        }
      when 'JOIN'
        group = Group.active.find(message.message_hash[:group_id])
        {
          :message => _("New user joined your group [%s].") % group.name,
          :icon => 'group_add',
          :url => url_for({:controller => 'group', :action => 'users', :gid => group.gid, :system_message_id => message.id})
        }
      when 'LEAVE'
        group = Group.active.find(message.message_hash[:group_id])
        user = User.find(message.message_hash[:user_id])
        {
          :message => _("%{user_name} left your group %{group_name}.") % {:user_name => user.name, :group_name => group.name},
          :icon => 'group_delete',
          :url => url_for({:controller => 'user', :action => 'show', :uid => user.uid, :system_message_id => message.id})
        }
      when 'APPROVAL_OF_JOIN'
        group = Group.active.find(message.message_hash[:group_id])
        {
          :message => _("You are approved to join the group %s.") % group.name,
          :icon => 'group_add',
          :url => url_for({:controller => 'group', :action => 'show', :gid => group.gid, :system_message_id => message.id})
        }
      when 'DISAPPROVAL_OF_JOIN'
        group = Group.active.find(message.message_hash[:group_id])
        {
          :message => _("You are disapproved to join the group %s.") % group.name,
          :icon => 'group_delete',
          :url => url_for({:controller => 'group', :action => 'show', :gid => group.gid, :system_message_id => message.id})
        }
      when 'FORCED_JOIN'
        group = Group.active.find(message.message_hash[:group_id])
        {
          :message => _("You are now member of the group [%s].") % group.name,
          :icon => 'group_add',
          :url => url_for({:controller => 'group', :action => 'show', :gid => group.gid, :system_message_id => message.id})
        }
      when 'FORCED_LEAVE'
        group = Group.active.find(message.message_hash[:group_id])
        {
          :message => _("You are forced to leave the group [%s].") % group.name,
          :icon => 'group_delete',
          :url => url_for({:controller => 'group', :action => 'show', :gid => group.gid, :system_message_id => message.id})
        }
      else
        nil
    end
  rescue ActiveRecord::RecordNotFound => e
    # FIXME 不要データの削除は表示タイミングでやるべきではないかも
    message.destroy
    nil
  end

  def enquete_cookie_key
    "clicked_enquete_#{SKIP_VERSION}"
  end

  def enable_enquete?
    GetText.locale.to_s == 'ja' && !(SkipEmbedded::InitialSettings['enable_enquete_for_oss'] == "lovelyskip" || cookies[enquete_cookie_key] == 'true')
  end
end
