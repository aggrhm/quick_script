
class @TodoItem extends @Model
	Model.includeAdapter(new ModelAdapter({
		load_url : '/api/todo_items',
		save_url : '/api/todo_item'
	}), this)
	Model.includeCollection(this)

	init : =>
		@addFields ['description', 'notes'], ''
		@addFields ['done'], false
		@addFields ['created_at', 'updated_at'], 0
		@addComputed 'created_at_date', ->
			Date.from_utc(@created_at())
		@addComputed 'created_at_str', ->
			@created_at_date().format('longDate')
