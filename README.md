QuickScript Javascript Framework
================================

QuickScript is a javascript library that enhances KnockoutJS to bind to persistent database models and provide a dynamic view structure. The key components are:

* **View** : a javascript representation of HTML layouts and templates used to manipulate models
* **Model** : a bindable representation of a database model to handle JSON response
* **Adapter** : an interface to talk to a JSON-responsive API server

Together, these components allow you to talk to a database and update views dynamically. For example, views can be embedded within other views, allowing complex layouts.

Installation
------------

1. To use QuickScript with Rails, add it to your gem file.

		gem "quick_script"

	The additional gems are also helpful, but optional

		gem "compass-rails"		# for compass css-styling support
		gem "tinymce-rails"		# for tinymce editor support

2. Next, you'll want to add include the helper module in the controller for useful rails controller functionality

		class ApplicationController
			include QuickScript::Interaction
			...
		end

3. Update your application.html.erb file. 

	You will want to include your view templates. I normally create them in my "app/views/shared" folder as "views.html.erb" or "templates.html.erb". Whatever you name them, include them in your application.html.erb layout file using render tags.

	Next, add the QuickScript initialization tag. For this README, let's assume we're building a TodoList application that talks to a server having multiple Todo items. Your layout file should look like the following:

		<!DOCTYPE html>
		<html>
		<head>
			<title>TodoListApp</title>
			<%= stylesheet_link_tag    "application", :media => "all" %>
			<%= javascript_include_tag "application" %>
			<%= render :partial => 'shared/templates' %>
			<%= render :partial => 'shared/views' %>
			<%= csrf_meta_tags %>
		</head>
		<body>
			<%= include_view_box %>
			<%= include_quick_script_init "TodoListApp" %>
		</body>
		</html>

4. Add the appropriate 'requires' to javascript and css asset files. To include everything, just add the following to both the application.js and application.css files:

		//= require quick_script

5. Next you'll want to create your views.js.coffee and models.js.coffee files. This is where the heart of all your client-side code will be. Views will be the logic tied to your view templates, and models will be the models that encapsulate the data retrieved from your API server. First, you'll want to setup your application-level view which initializes everything in views.js.coffee.

		class TodoListApp extends @AppView	# note it extends AppView, not View
			init : ->
				@addView 'mylist', TodoListView, 'view-todolist'
				# any other app initialization javascript stuff you want to do
			load : ->
				@selectView 'mylist'

	Don't forget to add these files to your application.js

		//= require models
		//= require view_models

5. That's it! Now start creating views for your application. Let's continue with our TodoList example.  

Models
------

First, let's define the classes that will tie in to the database models.

		class Task extends @Model
			@includeCollection(this)	# provides Task.Collection
			@includeAdapter				# provides Task.Adapter
				new ModelAdapter
					load_url : '/tasks'
					save_url : '/task'
			, this
			init : ->
				# match fields in json response. initialize with a value
				ko.addField 'description', '', this
				ko.addField 'completed', false, this

That should be enough for this example. Now let's use our Todo model in a view.

Views
-----

A standard view looks liks the following:

		class TodoListView extends @View
			init : ->
			# here we could add additional sub-views if we wanted...
			@tasks = new Task.Collection()	# our list of views
			@task = new Task()		# hold our new task
			load : ->
				@tasks.load ['my_tasks']
			saveTask : =>
				@task.save ['description'], (resp)=>
					if @task.hasErrors()
						Overlay.notify 'Couldn't save this task!', 'bg-red'
					else
						Overlay.notify 'Task saved!'
						@task.reset()

Then, in our view templates file, we need to add our html code that binds to the view:

		<%= jqtpl 'view-todolist' do %>
			<div class="todolist">
				<ul class="task" data-bind="foreach : tasks.views">
					<li>
						<span data-bind="text : model.description"></span>
					</li>
				</ul>
			</div>
			<div class="newtask">
				<input type="text" placeholder="Enter new task..." data-bind="value : task.description, handleEnter : saveTask" />
			</div>
		<% end %>

ModelAdapters
-------------

More coming soon...

Rails API
---------

More coming soon...

Tips
----

1. Any thing you want to bind to must be constructed in the init method
2. Each view should generally keep its own model instances to prevent other views from changing (especially views for editing models)
3. Use the 'absorb' method on models to preserve bindings, instead of instantiating
4. Use the load method on a view to initialize the view before display

Thanks To...
------------

All the contributors to KnockoutJS. Probably one of the best JS libraries since jQuery.

