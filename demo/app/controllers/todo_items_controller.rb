class TodoItemsController < ApplicationController

  before_filter :load_todo_item

  def index
    if params[:id]
      render :json => json_resp(@todo_item.to_api)
    else
      @todo_items = respond_to_scope do |scope|
        scope.all {
          TodoItem.limit(@scope.limit).offset(@scope.offset)
        }
      end
      render :json => json_resp(@todo_items.collect{|t| t.to_api})
    end
  end

  def save
    @todo_item.description = params[:description] if params[:description]
    @todo_item.done = params[:done] if params[:done]
    @todo_item.notes = params[:notes] if params[:notes]

    @todo_item.done = false if @todo_item.done.nil?
    @todo_item.save
    render :json => json_resp(@todo_item.to_api)
  end

  def delete
    @todo_item.destroy
    render :json => json_resp(@todo_item.to_api)
  end

  protected

  def load_todo_item
    @todo_item = TodoItem.find_by_id(params[:id]) || TodoItem.new
  end

end
