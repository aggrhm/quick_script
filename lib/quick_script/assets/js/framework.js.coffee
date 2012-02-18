@initKO = ->
	ko.bindingHandlers.fadeVisible =
		init : (element, valueAccessor) ->
			shouldDisplay = ko.utils.unwrapObservable(valueAccessor())
			if shouldDisplay then $(element).show() else $(element).hide()
		update : (element, value) ->
			shouldDisplay = value()
			if shouldDisplay then $(element).fadeIn('slow') else $(element).fadeOut()

	ko.bindingHandlers.slideVisible =
		init : (element, valueAccessor) ->
			shouldDisplay = ko.utils.unwrapObservable(valueAccessor())
			if shouldDisplay then $(element).show() else $(element).hide()
		update : (element, valueAccessor) ->
			shouldDisplay = ko.utils.unwrapObservable(valueAccessor())
			if shouldDisplay then $(element).slideDown('slow') else $(element).slideUp()

	ko.bindingHandlers.handleEnter =
		init : (element, valueAccessor, bindingsAccessor, viewModel) ->
			$(element).keypress (ev)->
				if (ev.keyCode == 13)
					action = valueAccessor()
					val = bindingsAccessor().value
					val($(element).val())
					action.call(viewModel)
					return false

	ko.bindingHandlers.cropImage =
		init : (element, valueAccessor) ->
			opts = valueAccessor()
			$(element).css
				background : 'url(' + ko.utils.unwrapObservable(opts[0]) + ')',
				backgroundSize: 'cover',
				'background-position': 'center',
				backgroundColor: '#FFF',
				width: opts[1],
				height: opts[2],
				display: 'inline-block'

	ko.bindingHandlers.tinymce =
		init : (element, valueAccessor, bindingsAccessor, viewModel) ->
			options = {
				width : $(element).width(),
				height : $(element).height(),
				content_css : '/assets/screen/tinymce.css',
				theme : 'advanced',
				theme_advanced_toolbar_location : 'top',
				theme_advanced_buttons1 : 'bold, italic, underline, separator, undo, redo, separator, bullist, numlist, blockquote, separator, justifyleft, justifycenter, justifyright, separator, image, link, unlink, separator, code',
				theme_advanced_buttons2 : '',
				theme_advanced_buttons3 : ''
			}
			val = valueAccessor()
			options.setup = (ed) ->
				ed.onChange.add (ed, l) ->
					val(l.content)
			# handle destroying an editor (based on what jQuery plugin does)
			ko.utils.domNodeDisposal.addDisposeCallback element, ->
				ed = tinyMCE.get(element.id)
				if (ed)
					ed.remove()
					console.log('removing tinymce')
			
			setTimeout ->
					$(element).tinymce(options)
					if ($(element).attr('name') != 'undefined')
						ko.editors[$(element).attr('name')] = element.id
				, 100
			console.log('init tinymce')
		update : (element, valueAccessor) ->
			$(element).html(ko.utils.unwrapObservable(valueAccessor()))

	ko.bindingHandlers.fileupload =
		init : (element, valueAccessor, bindingsAccessor, viewModel) ->
			model = valueAccessor()
			$(element).fileupload(model.input.options)
			$(element).change (evt)->
				model.input.files(evt.target.files)
			model.fileupload = $(element).fileupload.bind($(element))
			model.selectFile = ->
				$(element).click()

	ko.bindingHandlers.calendar =
		init : (element, valueAccessor, bindingsAccessor, viewModel) ->
			$(element).fullCalendar('destroy')
			$(element).fullCalendar(ko.utils.unwrapObservable(valueAccessor()))
			viewModel.calendar = $(element).fullCalendar.bind($(element))

	ko.bindingHandlers.center =
		init : (element, valueAccessor, bindingsAccessor, viewModel) ->
			setTimeout ->
					$(element).center()
				, 1

	ko.bindingHandlers.progressbar =
		update: (element, valueAccessor) ->
			$(element).progressbar({value : ko.utils.unwrapObservable(valueAccessor())})

	ko.bindingHandlers.placeholder =
		init: (element, valueAccessor) ->
			fn = ->
				if ($(element).val().length > 0)
					$(element).siblings('label').hide()
				else
					$(element).siblings('label').show()
			$(element).live('blur change keyup', fn)
		update: (element, valueAccessor) ->
			if ($(element).val().length > 0)
				$(element).siblings('label').hide()
			else
				$(element).siblings('label').show()


	ko.absorbModel = (data, self) ->
		for prop, val of data
			continue if typeof(val) == "function"
			if !self[prop]?
				self[prop] = ko.observable(val)
			else if (typeof(self[prop].handleData) == "function")
				self[prop].handleData(val)
			else
				self[prop](val)
			self.fields.pushOnce(prop)
		self.model_state(ko.modelStates.READY)

	ko.saveModel = (fields, path, callback, self) ->
		if (self.model_state() != ko.modelStates.READY)
			console.log("Save postponed.")
			return
		opts = {}
		if (fields instanceof Array)
			fields.push('id')
			for prop in fields
				if self[prop].toJS?
					opts[prop] = self[prop].toJS()
				else
					opts[prop] = self[prop]()
		else
			opts = fields
		if (self.doDelete())
			opts['_delete'] = true
		$.ajax
			type : 'POST'
			url : path
			data : opts
			success : callback
			error : ->
				console.log("Save error encountered")
				self.model_state(ko.modelStates.READY)
		self.model_state(ko.modelStates.SAVING)

	ko.saveModelWithFile = (fields, fileparam, path, callback, self) ->
		if (self.model_state() != ko.modelStates.READY)
			console.log("Save postponed.")
			return
		opts = {}
		if (fields instanceof Array)
			fields.push('id')
			for prop in fields
				if self[prop].toJS?
					opts[prop] = self[prop].toJS()
				else
					opts[prop] = self[prop]()
		else
			opts = fields
		if (self.doDelete())
			opts['_delete'] = true
		filemodel = self[fileparam]
		up_opts = {}
		up_opts.paramName = fileparam
		up_opts.url = path
		up_opts.formData = opts
		up_opts.files = filemodel.input.files()
		filemodel.input.events.progress = (e, data)->
			val = parseInt( data.loaded / data.total * 100, 10 )
			self.saveProgress(val)
		filemodel.input.events.done = (e, data)->
			self.saveProgress(0)
			callback(data)
		filemodel.input.events.always = ->
			self.model_state(ko.modelStates.READY)

		filemodel.fileupload('add', up_opts)
		self.model_state(ko.modelStates.SAVING)

	ko.addFields = (fields, val, self) ->
		for prop in fields
			if (typeof(self[prop]) != "function")
				if (val instanceof Array)
					self[prop] = ko.observableArray()
				else
					self[prop] = ko.observable(val)
			else
				self[prop](val)
			if (typeof(prop) == "string")
				self.fields.pushOnce(prop)

	ko.addSubModel = (field, model, self) ->
		if self[field]?
			self[field].reset()
		else
			self[field] = new model()

	ko.intercepter = (observable, write_fn, self) ->
		underlying_observable = observable
		return ko.dependentObservable
			read: underlying_observable,
			write: (val) ->
				if (val != underlying_observable())
					write_fn.call(self, underlying_observable, underlying_observable(), val)

	ko.dirtyFlag = (root, isInitiallyDirty) ->
			result = ->
			_initialState = ko.observable(ko.toJSON(root))
			_isInitiallyDirty = ko.observable(isInitiallyDirty)

			result.isDirty = ko.dependentObservable ->
				return _isInitiallyDirty() || (_initialState() != ko.toJSON(root))

			result.reset = ->
				_initialState(ko.toJSON(root))
				_isInitiallyDirty(false)

			return result

	ko.copyObject = (obj, fields) ->
		ret = {}
		for prop in fields
			ret[prop] = obj[prop]
		return ret

	ko.modelStates = {}
	ko.modelStates.READY = 1
	ko.modelStates.LOADING = 2
	ko.modelStates.SAVING = 3
	ko.modelStates.EDITING = 4
	ko.editors = {}

jQuery.fn.extend
	to_s : ->
		$('<div>').append(this.clone()).remove().html()
	center : ->
    this.css("position","absolute")
    this.css("top", (($(window).height() - this.outerHeight()) / 2) + $(window).scrollTop() + "px")
    this.css("left", (($(window).width() - this.outerWidth()) / 2) + $(window).scrollLeft() + "px")
    return this
	koBind : (viewModel) ->
		this.each ->
			ko.cleanNode(this)
			ko.applyBindings(viewModel, this)
	koClean : ->
		this.each ->
			ko.cleanNode(this)


class @Model
	init : ->
	extend : ->
	constructor: (data, collection) ->
		@fields = []
		ko.addFields(['id'], '', this)
		@events = {}
		@load_fields = ['id']
		@load_url = "/"
		@save_url = "/"
		@collection = collection
		@db_state = ko.observable({})
		@errors = ko.observable([])
		@model_state = ko.observable(0)
		@doDelete = ko.observable(false)
		@saveProgress = ko.observable(0)
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
		@is_valid = ko.dependentObservable ->
				@errors().length == 0
			, this
		@handleData(data || {})
	handleData : (resp) ->
		ko.absorbModel(resp, this)
		@db_state(@toJS())
	load : (opts, callback)->
		$.getJSON @load_url, opts, (resp) =>
			ret_data = if opts.fields? then ko.copyObject(resp.data, opts.fields) else resp.data
			@handleData(ret_data)
			callback(resp) if callback?
		@model_state(ko.modelStates.LOADING)
	reloadFields : (fields, callback)->
		opts = ko.copyObject(@toJS(), @load_fields)
		opts['fields'] = fields
		@load(opts, callback)
	reload : (callback)->
		opts = ko.copyObject(@toJS(), @load_fields)
		@load(opts, callback)
	save : (fields, callback) ->
		console.log("Saving fields #{fields}")
		ko.saveModel fields, @save_url, (resp) =>
				@handleData(resp.data)
				callback(resp) if callback?
				#@collection.load() if @collection?
			, this
	saveWithFile : (fields, fileparam, callback) ->
		console.log("Saving fields #{fields} with file")
		if @[fileparam].input.present()
			ko.saveModelWithFile fields, fileparam, @save_url, (resp) =>
					@handleData(resp.data)
					callback(resp) if callback?
				, this
		else
			@save(fields, callback)
	reset : ->
		@model_state(ko.modelStates.LOADING)
		@id('')
		@init()
		@db_state(@toJS())
		@saveProgress(0)
		@model_state(ko.modelStates.READY)
	deleteModel : (callback)=>
		@doDelete(true)
		@save(['id'], callback)
	toJS : =>
		obj = {}
		for prop in @fields
			if typeof(@[prop].toJS) == 'function'
				obj[prop] = @[prop].toJS()
			else
				obj[prop] = @[prop]()
		obj
	absorb : (model) =>
		@reset()
		@handleData(model.toJS())

class @FileModel extends @Model
	extend : ->
		@input = {events: {}}
		@input.options =
			fileInput : null
			progress : (e, data)=>
				@input.events.progress(e, data)
			done : (e, data)=>
				@input.events.done(e, data)
			always : (e, data)=>
				@input.events.always(e, data)
		@input.files = ko.observable([])
		@input.present = ko.computed ->
				@input.files().length > 0
			, this
		@input.file = ko.computed ->
				if @input.present() then @input.files()[0] else null
			, this
		@input.filename = ko.computed ->
				if @input.present() then @input.file().name else ""
			, this
		@input.isImage = ->
			if @input.present() then @input.file().type.match('image.*') else false
	reset : ->
		super
		@input.files([])

class @Collection
	constructor: (opts) ->
		@opts = opts || {}
		@events = {}
		@scope = ko.observable(@opts.scope || [])
		@items = ko.observableArray([])
		@page = ko.observable(1)
		@limit = ko.observable(@opts.limit || 4)
		@title = ko.observable(@opts.title || 'Collection')
		@extra_params = ko.observable(@opts.extra_params || {})
		@model = @opts.model
		@path_url = @opts.path_url
		@template = ko.observable(@opts.template)
		@model_state = ko.observable(0)
		@is_ready = ko.dependentObservable ->
				@model_state() == ko.modelStates.READY
			, this
		@is_loading = ko.dependentObservable ->
				@model_state() == ko.modelStates.LOADING
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
	setScope : (scp, args) =>
		opts = args
		opts.unshift(scp)
		@scope(opts)
	load : (opts, callback)->
		@extra_params(opts.extra_params) if opts? && opts.extra_params?
		console.log("Loading items for #{@scope()}")
		$.getJSON @path_url, @loadOptions(), (resp) =>
			@handleData(resp.data)
			callback(resp) if callback?
			@events.onchange() if @events.onchange?
		@model_state(ko.modelStates.LOADING)
	loadScope : (scope, callback)->
		@scope(scope)
		@load(null, callback)
	handleData : (resp) =>
		mapped = (new @model(item, this) for item in resp)
		@items(mapped)
		@model_state(ko.modelStates.READY)
	nextPage : ->
		@page(@page() + 1)
		@load()
	prevPage : ->
		@page(@page() - 1)
		@load()
	hasItems : ->
		@items().length > 0
	getTemplate : ->
		@template()
	reset : ->
		@page(1)
		@items([])
	toJS : =>
		objs = []
		for item in @items()
			objs.push(item.toJS())
		objs

class @View
	init : ->
	constructor : (@name, @owner, @app)->
		@views = {}
		@events = {}
		@is_visible = ko.observable(false)
		@path = ko.observable(null)
		@view_name = ko.computed ->
				"view-#{@name}"
			, this
		@parts = []
		@view = null
		@init()
		@addViews()
	addViews : ->
	show : ->
		@is_visible(true)
	hide : ->
		@events.on_hide() if @events.on_hide?
		@is_visible(false)
	handlePath : (path) ->
		console.log("View [#{@name}] handling path '#{path}'")
		@path(path)
		@parts = @path().split('/')
	embed : ->
		console.log("Adding #{@name} to #{@owner}...")
		$(".view-#{@owner} .view-box").append("<div class='view-#{@name}' data-bind=\"visible : views.#{@name}.is_visible(), template : {name : 'view-#{@name}', data : views.#{@name}}\"></div>")
	addView : (name, view_class) ->
		@views[name] = new view_class(name, this, @app)
	viewList : ->
		list = for name, view of @views
			view
	embedViews : =>
		console.log("Embedding views...")
		for name, view of @views
			@views[name].embed()
	selectView : (view) ->
		last_view = @view
		if (last_view != view)
			console.log("View [#{view.name}] selected.")
			@view = view
			last_view.hide() if last_view?
			view.show()
			window.onbeforeunload = @view.events.before_unload
	getViewName : (view) ->
		"view-#{view.name}"

class @OverlayView extends @View
	constructor : (@name, @templateID, @owner, @app)->
		super(@name, @owner, @app)
	show : (opts)=>
		overlay.add(this, opts)
	hide : =>
		overlay.remove(@name)

class @Account
	constructor : (@user_model)->
		@user = new @user_model()
		@login_url = "/"
		@register_url = "/"
		@reset_url = "/"
		@login_key = "email"
		@password_key = "password"
		@redirect = null
		@is_loading = ko.observable(false)
		@isLoggedIn = ko.dependentObservable ->
				!@user.is_new()
			, this
	setUser : (val)->
		if val != null
			@user.handleData(val)
	login : (login, password, callback)->
		@is_loading(true)
		opts = {}
		opts[@login_key] = login
		opts[@password_key] = password
		$.post @login_url, opts, (resp) =>
			@is_loading(false)
			if resp.meta == 200
				@setUser(resp.data)
			callback(resp) if callback?
	register : (login, password, opts, callback)->
		@is_loading(true)
		opts[@login_key] = login
		opts[@password_key] = password
		$.post @register_url, opts, (resp) =>
			@is_loading(false)
			if resp.meta == 200
				@setUser(resp.data)
			callback(resp) if callback?
	save : (model, fields, callback) ->
		console.log("Saving fields #{fields}")
		ko.saveModel fields, @save_url, (resp) =>
				model.handleData(resp.data)
				@user.absorb(model) if model.is_valid()
				callback(resp) if callback?
				#@collection.load() if @collection?
			, model
	resetPassword : (login, callback)->
		@is_loading(true)
		opts = {}
		opts[@login_key] = login
		$.post @reset_url, opts, (resp) =>
				@is_loading(false)
				callback(resp) if callback?

class @AppViewModel extends @View
	constructor : ->
		super('app', null, this)
	route : (path) ->
		console.log("Loading path '#{path}'")
		@handlePath(path)
	setUser : (user)->
	redirectTo : (path) ->
		$.history.load(path)

@initApp = ->
	appViewModel = @appViewModel
	overlay = @overlay

	appViewModel.setUser(@CURRENT_USER)

	# navigation
	$.history.init (hash) ->
			if hash == ""
				appViewModel.route('/')
			else
				appViewModel.route(hash)
		, { unescape : ",/" }

	# layout bindings
	$('body').koBind(appViewModel)

