class @TodoItemView extends @View
	init : =>
		@todo_item = @model
	deleteItem : =>
		@todo_item.removeFromCollection()

class @HomeView extends @View
	init : =>
		@todo_items = new TodoItem.Collection()
		@todo_items.setView(TodoItemView, this)
		@new_item = new TodoItem()
	addTodoItem : =>
		@new_item.id(Date.now())
		@new_item.done(false)
		@new_item.created_at(Date.now_utc())
		@todo_items.addItem(new TodoItem(@new_item.toJS()))
		@new_item.reset()
	fadeOutItem : (node)=>
		$(node).fadeOut()

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
