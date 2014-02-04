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

class SearchController < ApplicationController

  # tab_menu
  def entry_search
    @main_menu = @title = _('Entries')

    params[:tag_select] ||= "AND"
    find_params = BoardEntry.make_conditions(current_user.belong_symbols, {:keyword =>params[:keyword],
                                               :tag_words => params[:tag_words],
                                               :tag_select => params[:tag_select]})

    if params[:user] or params[:group]
      find_params[:conditions][0] << " and ("
    end

    additional_state = ""
    if params[:user]
      additional_state << "board_entries.entry_type = 'DIARY'"
    end
    if params[:group]
      additional_state << " or " unless additional_state.empty?
      additional_state << "board_entries.entry_type = 'GROUP_BBS'"
    end

    find_params[:conditions][0] << additional_state

    if params[:user] or params[:group]
      find_params[:conditions][0] << " ) "
    end

    @entries = BoardEntry.scoped(
      :conditions => find_params[:conditions],
      :include => find_params[:include] | [ :user, :state ]
    ).order_new.aim_type(params[:type] || 'entry').paginate(:page => params[:page], :per_page => 25)

    if @entries.empty?
      flash.now[:notice] = _('No matching data found.')
    end

    @symbol2name_hash = BoardEntry.get_symbol2name_hash @entries
    @tags = BoardEntry.get_popular_tag_words
  end

  # tab_menu
  def share_file_search
    @search = ShareFile.accessible(current_user).tagged(params[:tag_words], params[:tag_select])
    @search =
      if params[:sort_type] == "file_name"
        @search.descend_by_file_name.search(params[:search])
      else
        @search.descend_by_date.search(params[:search])
      end
    @share_files = @search.paginate(:page => params[:page], :per_page => 25)
    params[:tag_select] ||= "AND"
    params[:sort_type] ||= "date"

    @main_menu = @title = _('Files')
    @tags = ShareFile.get_popular_tag_words

    flash.now[:notice] = _('No matching shared files found.') if @share_files.empty?
  end

  #全文検索
  def full_text_search
    @main_menu = @title = _('Full-text Search')

    params[:target_aid] ||= "all"
    params[:query] = params[:full_text_query] unless params[:full_text_query].blank?
    params[:per_page] = 10
    params[:offset] ||= 0

    search = Search.new(params, current_user.belong_symbols_with_collaboration_apps)
    FullTextSearchLog.create(:query => params[:query]) if SkipEmbedded::InitialSettings['enable_collect_logs']
    if search.error.blank?
      # TODO: インスタンス変数に代入することなく@searchで画面表示
      @invisible_count = search.invisible_count
      make_instance_variables search.result
    else
      # Searchクラスのメッセージの国際化
      N_("Please input search query.")
      N_("Access denied by search node. Please contact system administrator.")
      @error_message = search.error
    end
  end

  # ログ解析のために全文検索の結果URLクリックでの遷移をログに残すためのAction
  # 全文検索の結果URLクリック時に非同期でリクエストされる
  def touch_full_text_search
    render :text => '', :layout => false
  end

private
  # 全文検索の各画面用に@変数を作成するメソッド
  def make_instance_variables search_result
    @result_lines = search_result[:elements]
    @max_count = search_result[:header][:count]
    @per_page = search_result[:header][:per_page]

    prev_offset = search_result[:header][:prev].empty? ? nil : search_result[:header][:start_count] - @per_page - 1
    next_offset = search_result[:header][:next].empty? ? nil : search_result[:header][:start_count] + @per_page - 1

    @result_info_locals = {
      :query => params[:query],
      :prev_offset => prev_offset,
      :next_offset => next_offset,
      :max_count => @max_count,
      :start_count => search_result[:header][:start_count],
      :end_count => search_result[:header][:end_count]
    }

    range_max = 9 # 今のページから前後何ページ分の範囲をooooooで表現するか
    current_page = search_result[:header][:start_count] / @per_page + 1 # 何ページ目か
    total_page_count = (@max_count - 1) / @per_page + 1 # 全部で何ページあるか
    start_index = current_page - range_max
    start_index = 1 if start_index <= 0
    end_index = current_page + range_max
    end_index = total_page_count if end_index > total_page_count
    end_index = 100 if end_index > 100

    @page_navi_locals = {
      :query => params["query"],
      :prev_offset => prev_offset,
      :next_offset => next_offset,
      :per_page => @per_page,
      :current_page => current_page,
      :start_index => start_index,
      :end_index => end_index
    }
  end

end
