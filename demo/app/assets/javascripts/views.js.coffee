class @HomeView extends @View
	init : =>

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
