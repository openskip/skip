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

class EventController < ApplicationController

  def new
    @event = Event.new
  end

  def create
    @event = Event.new(params[:event])
    @event.creator_id = current_user.id
    if @event.save
      flash[:notice] = _('Event was created successfully.')
      redirect_to event_path(@event)
    else
      render :action => 'new'
    end
  end

  def show
    @event = Event.find(params[:id])
  end

end