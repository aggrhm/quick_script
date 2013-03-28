@QuickScript = {}

class @Model
	init : ->
	extend : ->
	constructor: (data, collection, opts) ->
		@fields = []
		ko.addFields(['id'], '', this)
		@events = {}
		@adapter = if @initAdapter? then @initAdapter() else null
		@collection = collection
		@db_state = ko.observable({})
		@errors = ko.observable([])
		@model_state = ko.observable(0)
		@saveProgress = ko.observable(0)
		if opts?
			@is_submodel = opts.is_submodel
		@extend()
		@init()
		@is_ready = ko.dependentObservable ->
				@model_state() == ko.modelStates.READY
			, this
		@is_loading = ko.dependentObservable ->
				@model_state() == ko.modelStates.LOADING
			, this
		@is_saving = ko.dependentObservable ->
				@model_state() == ko.modelStates.SAVING
			, this
		@is_editing = ko.dependentObservable ->
				@model_state() == ko.modelStates.EDITING
			, this
		@is_new = ko.dependentObservable ->
				@id() == ''
			, this
		@is_dirty = ko.dependentObservable ->
				JSON.stringify(@db_state()) != JSON.stringify(@toJS())
			, this
		@has_errors = ko.dependentObservable ->
				@errors().length > 0
			, this
		@handleData(data || {})
	addFields : (fields, def_val) ->
		ko.addFields fields, def_val, this
	addComputed : (field, fn) ->
		this[field] = ko.computed fn, this
	addSubModel : (field_name, class_name) ->
		ko.addSubModel field_name, class_name, this
	handleData : (resp) ->
		ko.absorbModel(resp, this)
		@db_state(@toJS())
	load : (opts, callback)->
		@adapter.load
			data : opts
			success : (resp)=>
				ret_data = if opts.fields? then ko.copyObject(resp.data, opts.fields) else resp.data
				@handleData(ret_data)
				callback(resp) if callback?
		@model_state(ko.modelStates.LOADING)
	reloadFields : (fields, callback)->
		opts = @reloadOpts()
		opts['fields'] = fields
		@load(opts, callback)
	reload : (callback)->
		opts = @reloadOpts()
		@load(opts, callback)
	reloadOpts : =>
		{id : @id()}
	save : (fields, callback) ->
		console.log("Saving fields #{fields}")
		if (@model_state() != ko.modelStates.READY)
			console.log("Save postponed.")
			return
		opts = @toAPI(fields)
		opts['id'] = @id()
		@adapter.save
			data: opts
			progress : (ev, prog)=>
				@saveProgress( prog )
			success : (resp)=>
				@handleData(resp.data)
				callback(resp) if callback?
			error : (err)=>
				err = err || 'unknown'
				console.log("Save error encountered [" + err + "]")
				@model_state(ko.modelStates.READY)
				callback({meta : 500, data : {errors : ['An error occurred']}}) if callback?
		@model_state(ko.modelStates.SAVING)
	reset : ->
		#@model_state(ko.modelStates.LOADING)
		@id('')
		@init()
		@db_state(@toJS())
		@saveProgress(0)
		@model_state(ko.modelStates.READY)
	delete : (fields, callback)=>
		fields ||= ['id']
		if (@model_state() != ko.modelStates.READY)
			console.log("Delete postponed.")
			return
		opts = @toJS(fields)
		opts['id'] = @id()
		@adapter.delete
			data : opts
			success : (resp)=>
				@handleData(resp.data)
				callback(resp) if callback?
				@collection.removeItemById(@id()) if ((resp.meta == 200) && @collection?)
			error : =>
				console.log("Delete error encountered")
				@model_state(ko.modelStates.READY)
				callback({meta : 500, data : {errors : ['An error occurred']}}) if callback?
		@model_state(ko.modelStates.SAVING)
	removeFromCollection : =>
		@collection.removeItemById(@id()) if @collection?
	toJS : (flds)=>
		flds ||= @fields
		obj = {}
		for prop in flds
			if typeof(@[prop].toJS) == 'function'
				obj[prop] = @[prop].toJS()
			else
				obj[prop] = @[prop]()
		obj
	toAPI : (flds)=>
		flds ||= @fields
		obj = {}
		for prop in flds
			if typeof(@[prop].toAPI) == 'function'
				val = @[prop].toAPI()
				if val != null
					if val instanceof File
						obj[prop] = val
					else
						obj[prop] = JSON.stringify val
			else if typeof(@[prop].toJS) == 'function'
				obj[prop] = @[prop].toJS()
			else
				val = @[prop]()
				if val instanceof Object
					obj[prop] = JSON.stringify(val)
				else
					obj[prop] = val if val != null
		obj
	toJSON : (flds)=>
		JSON.stringify(@toJS(flds))
	getClass : =>
		@constructor
	toClone : =>
		m = new(@getClass())
		m.absorb(this)
		return m
	absorb : (model) =>
		@reset()
		@handleData(model.toJS())
Model.includeCollection = (self)->
	self.Collection = class extends Collection
		constructor : (opts)->
			super(opts)
			@adapter = self.Adapter
			@model = self
Model.includeAdapter = (adapter, self)->
	self.Adapter = adapter
	self::initAdapter = (=> adapter)

class @FileModel extends Model
	extend : ->
		@input = {}
		@input.files = ko.observable([])
		@input.file_uri = ko.observable('')
		@input.files.subscribe (val)=>
			if val.length > 0 && FileReader?
				@input.file_uri('')
				reader = new FileReader()
				reader.onloadend = (ev)=>
					console.log('input loaded')
					@input.file_uri(ev.target.result)
				reader.readAsDataURL(val[0])
		, this
		@input.present = ko.computed ->
				@input.files().length > 0
			, this
		@input.file = ko.computed ->
				if @input.present() then @input.files()[0] else null
			, this
		@input.filename = ko.computed ->
				if @input.present() then @input.file().name else ""
			, this
		@input.is_image = ko.computed ->
				if (@input.present() && @input.file().type?) then @input.file().type.match('image.*') else false
			, this
		@input.clear = => @input.files([])
	reset : =>
		super
		@input.files([])
	toAPI : =>
		@input.file()

class @Collection
	init : ->
	constructor: (opts) ->
		@opts = opts || {}
		@events = {}
		@_reqid = 0
		@scope = ko.observable(@opts.scope || [])
		@items = ko.observableArray([])
		@views = ko.observableArray([])
		@view_model = ko.observable(@opts.view || View)
		@view_owner = ko.observable(@opts.view_owner || null)
		@page = ko.observable(1)
		@limit = ko.observable(@opts.limit || 100)
		@title = ko.observable(@opts.title || 'Collection')
		@count = ko.observable(0)
		@extra_params = ko.observable(@opts.extra_params || {})
		@model = @opts.model || Model
		@adapter = @opts.adapter || new ModelAdapter()
		@template = ko.observable(@opts.template)
		@model_state = ko.observable(0)
		@is_ready = ko.dependentObservable ->
				@model_state() == ko.modelStates.READY
			, this
		@is_loading = ko.dependentObservable ->
				@model_state() == ko.modelStates.LOADING
			, this
		@is_updating = ko.dependentObservable ->
				(@model_state() == ko.modelStates.LOADING) || (@model_state() == ko.modelStates.UPDATING)
			, this
		@is_appending = ko.dependentObservable ->
				@model_state() == ko.modelStates.APPENDING
			, this
		@is_inserting = ko.dependentObservable ->
				@model_state() == ko.modelStates.INSERTING
			, this
		@loadOptions = ko.dependentObservable ->
				opts = @extra_params()
				opts['scope'] = @scope()
				opts['limit'] = @limit()
				opts['page'] = @page()
				opts
			, this
		@scope = ko.intercepter @scope, (obs, prev, curr) ->
				obs(curr)
				console.log("Scope changed from #{prev} to #{curr}")
				#@load()
			, this
		@scopeSelector = ko.observable()
		@scopeSelector.subscribe (val) ->
				opts = @scope()
				opts[@scopeSelector()] = []
				@scope(opts)
			, this
		@hasItems = ko.dependentObservable ->
				@items().length > 0
			, this
		@length = ko.computed ->
				@items().length
			, this
		@init()
	setScope : (scp, args) =>
		opts = args
		opts.unshift(scp)
		@scope(opts)
	setView : (view_model, view_owner) =>
		@view_model(view_model)
		@view_owner(view_owner)
	_load : (scope, op, callback)->
		console.log("Loading items for #{scope}")
		op ||= Collection.REPLACE
		reqid = ++@_reqid
		opts = @loadOptions()
		opts.scope = scope
		@adapter.index
			data : opts
			success : (resp)=>
				return if @_reqid != reqid
				@handleData(resp.data, op)
				@count(resp.count) if resp.count?
				callback(resp) if callback?
				@events.onchange() if @events.onchange?
		if op == Collection.REPLACE
			@model_state(ko.modelStates.LOADING)
		if op == Collection.UPDATE
			@model_state(ko.modelStates.UPDATING)
		else if op == Collection.APPEND
			@model_state(ko.modelStates.APPENDING)
		else if op == Collection.INSERT
			@model_state(ko.modelStates.INSERTING)
	load : (scope, opts)->
		opts = {callback: opts} if (!opts?) || (opts instanceof Function)
		@reset() unless opts.reset? && !opts.reset
		@scope(scope) if scope?
		@_load(@scope(), Collection.REPLACE, opts.callback)
	update : (callback)->
		@_load(@scope(), Collection.UPDATE, callback)
	insert : (scope, callback)->
		@_load(scope, Collection.INSERT, callback)
	append : (scope, callback)->
		@_load(scope, Collection.APPEND, callback)
	handleData : (resp, op) =>
		models = []
		views = []
		op ||= Collection.REPLACE
		cls = @view_model()
		if (op == Collection.REPLACE) || (op == Collection.UPDATE)
			@items([]); @views([])
		for item, idx in resp
			model = new @model(item, this)
			models.push(model)
			views.push(new cls("view-#{model.id()}", @view_owner(), model))

		if !op? || op == Collection.REPLACE || op == Collection.UPDATE
			@items(models)
			@views(views)
		else if op == Collection.INSERT
			@items(models.concat(@items()))
			@views(views.concat(@views()))
		else if op == Collection.APPEND
			@items(@items().concat(models))
			@views(@views().concat(views))
		@model_state(ko.modelStates.READY)
	nextPage : ->
		@page(@page() + 1)
		@update()
	prevPage : ->
		@page(@page() - 1)
		@update()
	hasItems : ->
		@items().length > 0
	length : ->
		@items().length
	addItem : (item)->
		item.collection = this
		cls = @view_model()
		view = new cls("view-#{item.id()}", @view_owner(), item)
		@items.push(item)
		@views.push(view)
		return view
	removeItem : (idx)->
		@items.splice(idx, 1)
		@views.splice(idx, 1)
	getItemById : (id)->
		list = @items().filter ((item)=> item.id() == id)
		ret = if list.length > 0 then list[0] else null
	nthViews : (n, offset) ->
		@views().filter (el, i)->
			(i-offset) % n == 0
	removeDuplicates : ->
		ids = []
		@items().forEach (item, idx, array)=>
			if ids.includes(item.id())
				@items.splice(idx, 1)
				@views.splice(idx, 1)
			else
				ids.push(item.id())
	removeIf : (callback)->
		@items().forEach (item, idx, array)=>
			if callback(item, idx)
				@items.splice(idx, 1)
				@views.splice(idx, 1)
	removeItemById : (id)->
		@removeIf (item)=>
			item.id() == id
	getTemplate : ->
		@template()
	reset : ->
		@page(1)
		@items([])
		@views([])
	absorb : (model) =>
		@reset()
		@handleData(model.toJS())
	toJS : =>
		objs = []
		for item in @items()
			objs.push(item.toJS())
		objs
	toAPI : =>
		objs = []
		for item in @items()
			objs.push(item.toAPI())
		objs
		JSON.stringify(objs)

Collection.REPLACE = 0
Collection.INSERT = 1
Collection.APPEND = 2
Collection.UPDATE = 3

class @View
	init : ->
	constructor : (@name, @owner, @model)->
		@app = @owner.app if @owner?
		@views = {}
		@events = {}
		@templateID = "view-#{@name}"
		@fields = []
		@view_name = ko.computed ->
				@templateID
			, this
		@is_visible = ko.observable(false)
		@is_loading = ko.observable(false)
		@is_saving = ko.observable(false)
		@error = ko.observable('')
		@has_error = ko.computed (-> @error().length > 0), this
		@view = null
		@task = ko.observable(null)
		@prev_task = ko.observable(null)
		@transition = {type : 'fade', opts : {'slide_pos' : ko.observable(0), 'slide_index' : ko.observable(0)}}
		@transition.has_slide_css = (css, idx)=>
			@transition.opts['slide_css' + css]().includes? idx
		@init()
		@setupViewBox()
	show : ->
		@is_visible(true)
	hide : ->
		@events.before_hide() if @events.before_hide?
		@is_visible(false)
	setupViewBox : ->
		if @transition.type == 'slide'
			@task.subscribe (val)=>
				return
				opts = @transition.opts
				if val != null
					idx = @getViewBoxIndex(val)
					old_idx = opts.slide_index()
					new_el = $(@element).find('.slide-item-' + idx)
					old_el = $(@element).find('.slide-item-' + old_idx)
					if idx > old_idx
						new_el.addClass('next')
						new_el[0].offsetWidth if new_el[0]?
						new_el.addClass('left')
						old_el.addClass('left')
					else
						new_el.addClass('prev')
						new_el[0].offsetWidth if new_el[0]?
						new_el.addClass('right')
						old_el.addClass('right')
					setTimeout ->
						new_el.removeClass('next left prev right')
						old_el.removeClass('active next left prev right')
						new_el.addClass('active')
					, 600
					opts.slide_index(idx)
	load : ->
	reload : =>
		@load.apply(this, arguments)
	addView : (name, view_class, tpl) ->
		@views[name] = new view_class(name, this)
		@views[name].templateID = tpl
		@["is_task_#{name}"] = ko.computed ->
				@task() == name
			, this
		@["select_task_#{name}"] = =>
			@selectView(name)
	viewCount : ->
		Object.keys(@views).length
	viewList : ->
		list = for name, view of @views
			view
	selectView : (view_name) ->
		args = Array.prototype.slice.call(arguments)
		last_view = @view
		view = @views[view_name]
		if (last_view != view)
			console.log("View [#{view.name}] selected.")
			@view = view
			@prev_task(@task())
			@task(view.name)
			last_view.hide() if last_view?
			view.show()
			view.load.apply(view, args[1..])
			window.onbeforeunload = @view.events.before_unload
		else
			@view.reload.apply(@view, args[1..])
	isTask : (task) ->
		@task() == task
	getViewName : (view) ->
		view.templateID
	getViewBoxTemplate : (view) ->
		switch view.transition.type
			when 'slide'
				'viewbox-slide'
			else
				'viewbox'
	getViewBoxIndex : (view_name) ->
		arr = Object.keys(@views)
		arr.indexAt(view_name)
	getViewByIndex : (idx) ->
		keys = Object.keys(@views)
		@views[keys[idx]]
	afterRender : =>
		if @transition.type == 'slide'
			return
			setTimeout =>
				console.log('after render')
				idx = @getViewBoxIndex(@task())
				new_el = $(@element).find('.slide-item-' + idx)
				new_el.addClass('active')
			, 500
	showAsOverlay : (tmp, opts, cls)=>
		Overlay.add(this, tmp, opts, cls)
	showAsPopover : (el, tmp, opts)=>
		Overlay.popover(el, this, tmp, opts)
	hideOverlay : =>
		Overlay.remove(@name)
	hidePopover : =>
		Overlay.removePopover(@name)
	overlayVisible : =>
		Overlay.isVisible(@name)

class @ModelAdapter
	constructor : (opts)->
		@save_url = null
		@load_url = null
		@index_url = null
		@host = ''
		for prop,val of opts
			@[prop] = val
	load : (opts)->
		opts.type = 'GET'
		opts.url = @load_url
		opts.data["_cv"] = Date.now() if opts.data?
		@send opts
	index : (opts)->
		opts.type = 'GET'
		opts.url = @index_url || @load_url
		opts.data["_cv"] = Date.now() if opts.data?
		@send opts
	save_old : (opts)->
		$.ajax
			type : 'POST'
			url : @host + @save_url
			data : opts.data
			success : opts.success
			error : opts.error
	save : (opts)->
		opts.url = @save_url
		@send opts
	send : (opts)->
		ModelAdapter.send(@host, opts)
	delete : (opts)->
		opts.type = 'DELETE'
		opts.url = @save_url
		@send opts
	add_method : (fn_name, fn)->
		@[fn_name] = fn.bind(this)
	route_method : (fn_name, url, http_m)->
		http_m ||= 'POST'
		@add_method fn_name, (opts)->
			opts.url = url
			opts.type = http_m
			@send opts
			
ModelAdapter.send = (host, opts)->
	def_err_fn = ->
		opts.success({meta : 500, data : {errors : ['An error occurred.']}})
	opts.type = 'POST' if !opts.type?
	opts.url = host + opts.url
	opts.error = def_err_fn unless opts.error?
	opts.success = opts.callback if opts.callback?
	$.ajax_qs opts

class @AccountAdapter
	constructor : (opts)->
		@login_url = "/api/account/login"
		@logout_url = "/api/account/logout"
		@register_url = "/api/account/register"
		@enter_code_url = "/api/account/enter_code"
		@reset_url = "/api/account/reset"
		@activate_url = "/api/account/activate"
		@save_url = "/api/account/save"
		@load_url = "/api/account/load"
		@login_key = "email"
		@password_key = "password"
		@host = ""
		for prop,val of opts
			@[prop] = val
	login : (username, password, opts)->
		opts.data = {} unless opts.data?
		opts.url = @login_url
		opts.data[@login_key] = username
		opts.data[@password_key] = password
		@send opts
	logout : (opts)->
		opts.data = {}
		opts.url = @logout_url
		@send opts
	register : (data_opts, opts)->
		opts.data = data_opts
		opts.url = @register_url
		@send opts
	sendInviteCode : (code, opts)->
		opts.data = {code : code}
		opts.url = @enter_code_url
		@send opts
	save : (data_opts, opts) ->
		opts.data = data_opts
		opts.url = @save_url
		@send opts
	load : (opts) ->
		opts ||= {}
		$.ajax_qs
			type : 'POST'
			url : @load_url
			data : opts.data
			progress : opts.progress
			success : opts.success
			error : opts.error
	resetPassword : (login, opts)->
		opts.data = {}
		opts.data[@login_key] = login
		opts.url = @reset_url
		@send opts
	activate: (token, opts)->
		opts.data = {token : token}
		opts.url = @activate_url
		@send opts
	send : (opts)->
		ModelAdapter.send(@host, opts)
	delete : (opts)->
		opts.type = 'DELETE'
		opts.url = @save_url
		@send opts
	add_method : (fn_name, fn)->
		@[fn_name] = fn.bind(this)
	route_method : (fn_name, url, http_m)->
		http_m ||= 'POST'
		@add_method fn_name, (opts)->
			opts.url = url
			opts.type = http_m
			@send opts

class @LocalStore
LocalStore.save = (key, val, exp_days, callback)->
	Lawnchair ->
		@save {key : key, val : val}, callback
LocalStore.get = (key, callback)->
	Lawnchair ->
		@get key, (data)->
			if data?
				callback(data.val)
			else
				callback(null)


class @Application extends @View
	constructor : (user_model)->
		@app = this
		@path = ko.observable(null)
		@previous_path = ko.observable(null)
		@path_parts = []
		@title = ko.observable('')
		@redirectOnLogin = ko.observable(null)
		ko.addTemplate "viewbox", """
				<div data-bind='foreach : viewList()'>
					<div data-bind="fadeVisible : is_visible(), template : { name : getViewName, afterRender : afterRender, if : is_visible() }, attr : { id : templateID}, bindelem : true"></div>
				</div>
			"""
		ko.addTemplate "viewbox-slide", """
				<div class="view-slider" data-bind="style : {width : transition.opts.width + 'px', height : transition.opts.height + 'px'}, carousel : task">
					<div data-bind='foreach : viewList()'>
						<div class="slide-item" data-bind="template : { name : getViewName }, attr : {id : templateID, class : 'slide-item slide-item-' + $index()}, css : {}, style : {width : owner.transition.opts.width + 'px', height : owner.transition.opts.height + 'px'}, bindelem : true"></div>
					</div>
				</div>
			"""
		@current_user = new @account_model()
		@is_logged_in = ko.computed ->
				!@current_user.is_new()
			, this
		super('app', null)
	route : (path) ->
		console.log("Loading path '#{path}'")
		@setTitle(@name, true)
		@previous_path(@path())
		@path(path)
		@path_parts = @path().split('/')
		@path_parts.push('') unless @path_parts[@path_parts.length-1] == ''
		@handlePath(path)
	handlePath : (path) ->
	setUser : (data)->
		console.log(data)
		@current_user.handleData(data) if data != null
	redirectTo : (path) ->
		History.pushState(null, null, path)
	loginTo : (path, user_data, opts)->
		@current_user.handleData(user_data)
		if @redirectOnLogin() != null
			@redirectTo(@redirectOnLogin())
			@redirectOnLogin(null)
		else
			@redirectTo(path)
	logoutTo : (path, opts)->
		@current_user.reset()
		@redirectTo(path)
	runLater : (callback)->
		setTimeout callback, 10
	host : =>
		window.location.host
	setTitle : (title, setFull)->
		@title(title)
		setFull = setFull || false
		if setFull
			$('title').text(title)
		else
			$('title').text("#{@name} - #{title}")

QuickScript.initialize = (opts)->
	# parse options
	app_class = opts.view || 'AppView'
	current_user = opts.user || null

	# initialization
	QuickScript.initKO()
	app = new window[app_class]()
	app.setUser(current_user)

	# navigation
	History.Adapter.bind window, 'statechange', ->
		app.route(History.getRelativeUrl())

	# layout bindings
	$('body').koBind(app)
	app.afterRender()

	# override links
	$('a').live 'click', ->
		if this.href.includes(History.getRootUrl())
			History.pushState null, null, this.href
			return false
		else
			return true

	app.route(History.getRelativeUrl())
	return app

