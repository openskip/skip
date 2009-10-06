# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008-2009 TIS Inc.
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

module UsersHelper

  def output_users_result users, options = {}
    options = {:output_normal => true, :output_group_participation => false}.merge(options)

    output = ""
    if options[:output_normal]
      for user in users
        render_params = {:partial => 'users/user', :object => user}
        render_params.merge!(:locals => {:top_option => user_state(user)}) if options[:output_group_participation]
        output << render(render_params)
      end
    else
      columns = [ Admin::Setting.login_account, 'uid', 'name', 'email', 'section' ]
      columns.delete(Admin::Setting.login_account) unless user_name_mode?(:code)
      columns.delete('uid') unless user_name_mode?(:name)
      columns.delete('email') if Admin::Setting.hide_email
      columns.unshift('') if options[:output_group_participation]

      block = lambda{ |user, column|
        case column
        when ''
          user_state user
        when Admin::Setting.login_account
          h(user.code)
        when 'name'
          user_link_to user
        when 'email'
          %(<a href="mailto:#{user.email}">#{user.email}</a>)
        when 'section'
          h(user.section)
        else
          h(user.send(column))
        end
      }
      output = render( :partial => "shared/table",
                       :locals => { :records => users,
                                    :target_class => User,
                                    :table_columns => columns,
                                    :value_logic => block  } )
    end
    output
  end

  def user_state user
    # FIXME 前提条件がちょっと変わっただけで動作しなくなるロジックになっているので見直しが必要。
    output = ""
    if user.group_participations.first.owned?
      output << icon_tag('star') + _("Administrator")
    else
      output << icon_tag('user') + _("Member")
    end
    output
  end
end
