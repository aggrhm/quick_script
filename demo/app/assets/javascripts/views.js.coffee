
# TODOITEMVIEW - view for rendering TodoItem in a collection
class @TodoItemView extends @View
	init : =>
		@todo_item = @model
		@todo_item.done.subscribe (val)=>
			@updateStatus()
	deleteItem : =>
		@todo_item.delete ['id'], (resp) =>
			if resp.meta == 200
				@todo_item.removeFromCollection()
			else
				Overlay.notify 'Could not delete item!', 'bg-red'
	updateStatus : =>
		@todo_item.save ['done']

# HOMEVIEW - main view for showing todo list
class @HomeView extends @View
	init : =>
		@todo_items = new TodoItem.Collection()
		@todo_items.setView(TodoItemView, this)
		@new_item = new TodoItem()
	load : =>
		# load save items from server
		@todo_items.load ['all']
	addTodoItem : =>
		# save to server
		@new_item.save ['description'], (resp)=>
			if resp.meta == 200
				t = new TodoItem(resp.data)
				@todo_items.addItem(t)
				@new_item.reset()
			else
				Overlay.notify resp.data.errors[0], 'bg-red'
	highlightItem : (el)=>
		$(el).effect('highlight', {}, 3000) if (el.nodeType == 1 && !@todo_items.is_loading())
	fadeOutItem : (el)=>
		$(el).fadeOut()

# APPVIEW - application-level view
class @AppView extends @Application
	init : =>
		@name = "TodoApp"
		@addView 'home', HomeView, 'view-home'
	handlePath : =>
		switch @app.path_parts[1]
			when '', 'home'
				@selectView 'home'
			else
				@app.redirectTo '/'
