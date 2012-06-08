@initKO = ->
	ko.bindingHandlers.fadeVisible =
		init : (element, valueAccessor) ->
			shouldDisplay = ko.utils.unwrapObservable(valueAccessor())
			if shouldDisplay then $(element).show() else $(element).hide()
		update : (element, value) ->
			shouldDisplay = value()
			if shouldDisplay then $(element).fadeIn('slow') else $(element).hide()

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

	ko.bindingHandlers.validate =
		init : (element, valueAccessor) ->
			opts = valueAccessor()
			$(element).blur ->
				if opts.test()
					$(element).removeClass(opts.err_css)
					$(element).addClass(opts.ok_css)
				else
					$(element).removeClass(opts.ok_css)
					$(element).addClass(opts.err_css)
					opts.on_err() if opts.on_err?

	ko.bindingHandlers.cropImage =
		update : (element, valueAccessor) ->
			opts = valueAccessor()
			if opts[0]?
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
				theme : 'advanced',
				theme_advanced_toolbar_location : 'top',
				theme_advanced_buttons1 : 'bold, italic, underline, separator, undo, redo, separator, bullist, numlist, blockquote, separator, justifyleft, justifycenter, justifyright, separator, image, link, unlink, separator, code',
				theme_advanced_buttons2 : '',
				theme_advanced_buttons3 : ''
			}
			val = valueAccessor()
			options.setup = (ed) ->
				ed.onInit.add (ed, l) ->
					tinyMCE.dom.Event.add ed.getWin(), "blur", ->
						console.log('leaving...')
						val(ed.getContent())
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

	ko.bindingHandlers.jsfileupload =
		init : (element, valueAccessor, bindingsAccessor, viewModel) ->
			model = valueAccessor()
			$(element).fileupload(model.input.options)
			$(element).change (evt)->
				model.input.files(evt.target.files)
			model.fileupload = $(element).fileupload.bind($(element))
			model.selectFile = ->
				$(element).click()

	ko.bindingHandlers.fileupload =
		init : (element, valueAccessor, bindingsAccessor, viewModel) ->
			model = valueAccessor()
			$(element).change (evt)->
				model.input.files(evt.target.files)
			model.selectFile = ->
				$(element).click()

	ko.bindingHandlers.jqtabs =
		init : (element, valueAccessor, bindingsAccessor, viewModel) ->
			$(element).addClass('ui-tabs ui-widget ui-widget-content ui-corner-all')
			$(element).children('ul').first().addClass('ui-tabs-nav ui-helper-reset ui-helper-clearfix ui-widget-header ui-corner-all')
			$(element).children('ul').first().children('li').addClass('ui-state-default ui-corner-top')
			$(element).children('div').addClass('ui-tabs-panel ui-widget-content ui-corner-bottom')
			$(element).children('ul').first().find('li a').each (idx, el)->
				tab_id = $(el).parent()[0].id
				$(el).click ->
					valueAccessor()(tab_id)
		update : (element, valueAccessor, bindingsAccessor, viewModel) ->
			sel_tab = ko.utils.unwrapObservable(valueAccessor())
			$(element).children('ul').first().children('li').removeClass('ui-tabs-selected ui-state-active')
			$(element).children('ul').first().children("li##{sel_tab}").addClass('ui-tabs-selected ui-state-active')
			$(element).children('div').addClass('ui-tabs-hide')
			$(element).children("div##{sel_tab}").removeClass('ui-tabs-hide')

	ko.bindingHandlers.tabs =
		init : (element, valueAccessor, bindingsAccessor, viewModel) ->
			$(element).children('ul').first().find('li').each (idx, el)->
				tab_id = $(el)[0].id
				$(el).click ->
					valueAccessor()(tab_id)
		update : (element, valueAccessor, bindingsAccessor, viewModel) ->
			sel_tab = ko.utils.unwrapObservable(valueAccessor())
			$(element).children('ul').first().children('li').removeClass('selected')
			$(element).children('ul').first().children("li##{sel_tab}").addClass('selected')
			$(element).children('div').addClass('hidden')
			$(element).children("div##{sel_tab}").removeClass('hidden')
	ko.bindingHandlers.tab_views =
		update : (element, valueAccessor, bindingsAccessor, viewModel) ->
			sel_tab = ko.utils.unwrapObservable(valueAccessor())
			$(element).children('div').addClass('hidden')
			$(element).children("div##{sel_tab}").removeClass('hidden')

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

	ko.bindingHandlers.tip =
		init : (element, valueAccessor) ->
			opts = valueAccessor()
			content = ko.utils.unwrapObservable(opts['content'])
			$(element).poshytip
				className: 'tip-twitter',
				showTimeout: 1,
				alignTo: 'target',
				alignX: 'center',
				offsetY: 5,
				allowTipHover: false,
				fade: false,
				slide: false,
				content: content
		update : (element, valueAccessor) ->
			opts = valueAccessor()
			content = ko.utils.unwrapObservable(opts['content'])
			$(element).poshytip('update', content)


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

	ko.addFields = (fields, val, self) ->
		for prop in fields
			ko.addField prop, val, self

	ko.addField = (field, val, valid_fn, self) ->
		if !self?
			self = valid_fn
			valid_fn = null
		if (typeof(self[field]) != "function")
			if (val instanceof Array)
				self[field] = ko.observableArray()
			else
				self[field] = ko.observable(val)

			self["#{field}_valid"] = ko.computed( (-> (valid_fn.bind(self))(self[field]())), self) if valid_fn?
		else
			self[field](val)
		if (typeof(field) == "string")
			self.fields.pushOnce(field)

	ko.addSubModel = (field, model, self) ->
		if self[field]?
			self[field].reset()
		else
			self[field] = new model({}, self)
		self.fields.pushOnce(field) if typeof(field) == "string"

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

	ko.addTemplate = (templateName, templateMarkup) ->
		$('head').append("<script type='text/html' id='" + templateName + "'>" + templateMarkup + "<" + "/script>")

	ko.modelStates = {}
	ko.modelStates.READY = 1
	ko.modelStates.LOADING = 2
	ko.modelStates.SAVING = 3
	ko.modelStates.EDITING = 4
	ko.modelStates.INSERTING = 5
	ko.modelStates.APPENDING = 6
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

jQuery.ajax_qs = (opts)->
	data = new FormData()
	req = new XMLHttpRequest()
	for key, val of opts.data
		data.append key, val
	req.onreadystatechange = (ev)->
		if req.readyState == 4
			if req.status == 200
				resp = eval("(" + req.responseText + ")")
				opts.success(resp)
			else
				opts.error() if opts.error?
	req.upload.addEventListener('error', opts.error) if opts.error?
	if opts.progress?
		req.upload.addEventListener 'progress', (ev)->
			opts.progress(ev, Math.floor( ev.loaded / ev.total * 100 ))
	req.open opts.type, opts.url, true
	req.setRequestHeader 'X-CSRF-Token', jQuery('meta[name="csrf-token"]').attr('content')
	req.send(data)
	return req

class @Model
	init : ->
	extend : ->
	constructor: (data, collection) ->
		@fields = []
		ko.addFields(['id'], '', this)
		@events = {}
		@adapter = if @initAdapter? then @initAdapter() else null
		@collection = collection
		@db_state = ko.observable({})
		@errors = ko.observable([])
		@model_state = ko.observable(0)
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
		@has_errors = ko.dependentObservable ->
				@errors().length > 0
			, this
		@handleData(data || {})
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
			error : =>
				console.log("Save error encountered")
				@model_state(ko.modelStates.READY)
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
			error : =>
				console.log("Delete error encountered")
				@model_state(ko.modelStates.READY)
		@model_state(ko.modelStates.SAVING)
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
				obj[prop] = val if val != null
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

class @FileModel extends @Model
	extend : ->
		@input = {}
		@input.files = ko.observable([])
		@input.file_uri = ko.observable('')
		@input.files.subscribe (val)->
			if val.length > 0
				@input.file_uri('')
				reader = new FileReader()
				reader.onload = (ev)=>
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
				if @input.present() then @input.file().type.match('image.*') else false
			, this
		@input.clear = -> @input.files([])
	reset : ->
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
				callback(resp) if callback?
				@events.onchange() if @events.onchange?
		if op == Collection.REPLACE
			@model_state(ko.modelStates.LOADING)
		else if op == Collection.APPEND
			@model_state(ko.modelStates.APPENDING)
		else if op == Collection.INSERT
			@model_state(ko.modelStates.INSERTING)
	load : (scope, callback)->
		@scope(scope) if scope?
		@_load(@scope(), Collection.REPLACE, callback)
	update : (callback)->
		@_load(@scope(), Collection.REPLACE, callback)
	insert : (scope, callback)->
		@_load(scope, Collection.INSERT, callback)
	append : (scope, callback)->
		@_load(scope, Collection.APPEND, callback)
	handleData : (resp, op) =>
		models = []
		views = []
		op ||= Collection.REPLACE
		cls = @view_model()
		if op == Collection.REPLACE
			@items([]); @views([])
		for item, idx in resp
			model = new @model(item, this)
			models.push(model)
			views.push(new cls("view-#{model.id()}", @view_owner(), model))

		if !op? || op == Collection.REPLACE
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
	getTemplate : ->
		@template()
	reset : ->
		@page(1)
		@items([])
		@views([])
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

Collection.REPLACE = 0
Collection.INSERT = 1
Collection.APPEND = 2

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
		@error = ko.observable('')
		@has_error = ko.computed (-> @error().length > 0), this
		@view = null
		@task = ko.observable(null)
		@transition = {type : 'fade', opts : {'slide_left' : ko.observable(0)}}
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
				if val != null
					left = @getViewBoxIndex(val) * @transition.opts.width * -1
					console.log(left)
					@transition.opts.slide_left(left)
	load : ->
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
			@task(view.name)
			last_view.hide() if last_view?
			view.show()
			view.load.apply(view, args[1..])
			window.onbeforeunload = @view.events.before_unload
		else
			@view.load.apply(@view, args[1..])
	isTask : (task) ->
		@task() == task
	getViewName : (view) ->
		view.templateID
	getViewBoxTemplate : (view) ->
		switch view.transition.type
			when 'slide'
				'app-slide'
			else
				'app-view'
	getViewBoxIndex : (view_name) ->
		arr = Object.keys(@views)
		arr.indexAt(view_name)
	showAsOverlay : (tmp, opts, cls)=>
		Overlay.add(this, tmp, opts, cls)
	hideOverlay : =>
		Overlay.remove(@name)

class @ModelAdapter
	constructor : (opts)->
		@save_url = null
		@load_url = null
		@index_url = null
		for prop,val of opts
			@[prop] = val
	load : (opts)->
		opts.data["_cv"] = Date.now() if opts.data?
		$.getJSON @load_url, opts.data, (resp)->
			opts.success(resp)
	index : (opts)->
		opts.data["_cv"] = Date.now() if opts.data?
		$.getJSON (@index_url || @load_url), opts.data, (resp)->
			opts.success(resp)
	save_old : (opts)->
		$.ajax
			type : 'POST'
			url : @save_url
			data : opts.data
			success : opts.success
			error : opts.error
	save : (opts)->
		$.ajax_qs
			type : 'POST'
			url : @save_url
			data : opts.data
			progress : opts.progress
			success : opts.success
			error : opts.error
	send : (opts)->
		$.ajax_qs
			type : 'POST'
			url : opts.url
			data : opts.data
			success : opts.success
			error : opts.error
	delete : (opts)->
		$.ajax
			type : 'DELETE'
			url : @save_url
			data : opts.data
			success : opts.success
			error : opts.error
	add_method : (fn_name, fn)->
		@[fn_name] = fn.bind(this)

class @AccountAdapter
	constructor : (opts)->
		@login_url = "/account/login"
		@register_url = "/account/register"
		@enter_code_url = "/account/enter_code"
		@reset_url = "/account/reset"
		@save_url = "/account/save"
		@load_url = "/account/load"
		@login_key = "email"
		@password_key = "password"
		for prop,val of opts
			@[prop] = val
	login : (username, password, callback)->
		opts = {}
		opts[@login_key] = username
		opts[@password_key] = password
		$.post @login_url, opts, (resp) =>
			callback(resp)
	register : (opts, callback)->
		$.post @register_url, opts, (resp) =>
			callback(resp)
	sendInviteCode : (code, callback)->
		$.post @enter_code_url, {code : code}, (resp) =>
			callback(resp)
	save : (opts) ->
		opts ||= {}
		$.ajax_qs
			type : 'POST'
			url : @save_url
			data : opts.data
			progress : opts.progress
			success : opts.success
			error : opts.error
	load : (opts) ->
		opts ||= {}
		$.ajax_qs
			type : 'POST'
			url : @load_url
			data : opts.data
			progress : opts.progress
			success : opts.success
			error : opts.error
	resetPassword : (callback)->
		@is_loading(true)
		opts = {}
		opts[@username_key] = @username()
		$.post @reset_url, opts, (resp) =>
				@is_loading(false)
				callback(resp) if callback?
	send : (opts)->
		$.ajax_qs
			type : 'POST'
			url : opts.url
			data : opts.data
			progress : opts.progress
			success : opts.success
			error : opts.error
	add_method : (fn_name, fn)->
		@[fn_name] = fn.bind(this)

class @AppView extends @View
	constructor : (user_model)->
		@app = this
		@path = ko.observable(null)
		@path_parts = []
		@account_model = Model
		ko.addTemplate "app-view", """
				<div data-bind='foreach : viewList()'>
					<div data-bind="fadeVisible : is_visible(), template : { name : getViewName }, attr : { id : templateID}"></div>
				</div>
			"""
		ko.addTemplate "app-slide", """
				<div data-bind="style : {width : transition.opts.width + 'px', overflowX : 'hidden'}">
					<div class='view-slider' data-bind="style : {width : ((viewCount()+1) * transition.opts.width) + 'px', height : transition.opts.height + 'px', clear : 'both', marginLeft : transition.opts.slide_left() + 'px', 'position' : 'relative'}">
						<div data-bind='foreach : viewList()'>
							<div data-bind="template : { name : getViewName }, attr : {id : templateID}, style : {width : owner.transition.opts.width + 'px', left : ($index() * owner.transition.opts.width) + 'px', 'position' : 'absolute'}"></div>
						</div>
					</div>
					<div style='clear: both;'></div>
				</div>
			"""
		super('app', null)
		@current_user = new @account_model()
		@is_logged_in = ko.dependentObservable ->
				!@current_user.is_new()
			, this
	route : (path) ->
		console.log("Loading path '#{path}'")
		@path(path)
		@path_parts = @path().split('/')
		@handlePath(path)
	handlePath : (path) ->
	setUser : (data)->
		console.log(data)
		@current_user.handleData(data) if data != null
	redirectTo : (path) ->
		$.history.load(path)

@initApp = ->
	appViewModel = @appViewModel

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

