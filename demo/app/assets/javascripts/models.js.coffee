
class @TodoItem extends @Model
	Model.includeAdapter(new ModelAdapter({
		load_url : '/api/todo_items',
		save_url : '/api/todo_item'
	}), this)
	Model.includeCollection(this)

	init : =>
		@addFields ['description'], ''
		@addFields ['done'], false
		@addFields ['created_at', 'updated_at'], 0
		@created_at_date = ko.computed ->
			Date.from_utc(@created_at())
		, this
		@created_at_str = ko.computed ->
			@created_at_date().format('longDate')
		, this
