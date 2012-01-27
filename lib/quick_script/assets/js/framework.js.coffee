## EXTENSIONS
Array.prototype.indexAt = (val) ->
	for i in this.length
		if this[i] == val
			return i
	return -1
Array.prototype.includes = (val) ->
	return this.indexAt(val) != -1
Array.prototype.pushOnce = (item) ->
	if (!this.includes(item))
		this.push(item)

## PAGETIMER
class @PageTimer
	constructor: (func, time) ->
		@callback = func
		@frequency = time * 1000
		@t_id = -1
	start : ->
		@t_id = setInterval(@callback, @frequency)
	stop : ->
		clearInterval(@t_id)
	setFrequency : (time) ->
		@stop()
		@frequency = time * 1000
		@start()
	getFrequency : (time) ->
		return @frequency / 1000
	increasePollTime : ->
		@setFrequency( @getFrequency() + (@getFrequency() % 5 == 0 ? 9 : 1) )

## NOTIFIER
class @Notifier
	constructor: ->
		@popup = null
		@tid = null
		@nids = []
	hasSupport : ->
		if (window.webkitNotifications)
			return true
		else
			return false
	hasPermission : ->
		return (window.webkitNotifications.checkPermission() == 0)
	requestPermission : (cb) ->
		window.webkitNotifications.requestPermission ->
			cb(window.webkitNotifications.checkPermission() == 0) if (cb)
	notify : (icon, title, body, opts) ->
		if (@hasSupport() && @hasPermission() && !@isActive())
			opts = {} if !opts?
			stay = opts["stay"]
			delay = opts["delay"]
			nid = opts["nid"]
			if (nid?)
				if (@nids.includes(nid))
					return false
				else
					@nids.pushOnce(nid)
			@popup = window.webkitNotifications.createNotification(icon, title, body)
			if (!stay? || !stay)
				@popup.ondisplay = ->
					setTimeout('notifier.Hide()', 5000)

			if (delay?)
				@tid = setTimeout('notifier.popup.show()', delay * 1000)
			else
				@popup.show()
			return true

		return false

	hide : ->
		if (@popup != null)
			@popup.cancel()
			@popup = null
		if (@tid != null)
			clearTimeout(@tid)
			@tid = null
	isActive : ->
		if (@popup != null)
			return true
		else
			return false

## OVERLAY
class @Overlay
	constructor : ->
		@zindex = 100
		@notifyTimer = null
		@title = ko.observable()
		@message = ko.observable()
	closeDialog : =>
		@remove('dialog')
	add : (id, template, vm, options) =>
		options = {} if !options?
		options['z-index'] = @zindex
		$('body').prepend("<div class='backdrop'></div><div id='overlay-" + id + "' class='overlay'><div class='content' data-bind=\"template: '" + template + "'\"></div></div>")
		$('#overlay-' + id).css(options)
		$('#overlay-' + id).css({'margin-left' : -1 * $('#overlay-' + id).width() / 2})
		$('.backdrop').click ->
			console.log('backdrop clicked.')
			@remove(id)
		$('#overlay-' + id).koBind(vm)
	dialog : (tpl, title, msg) ->
		@title(title)
		@message(msg)
		@add('dialog', tpl, this, { width : 300 })
	notify : (msg, cls, tm) ->
		cls = cls || ''
		tm = tm || 3000
		@clearNotifications()
		$('body').prepend("<div id='notify' class='notify' style='display: none;'>" + msg + "</div>")
		if (cls)
			$('#notify').addClass(cls)
		$('#notify').slideDown 'slow', ->
			@notifyTimeout = setTimeout ->
					$('#notify').fadeOut('slow')
				, tm
	clearNotifications : ->
		clearTimeout(@notifyTimeout)
		$('#notify').remove()
	remove : (id) ->
		$('#overlay-' + id).koClean()
		$('#overlay-' + id).remove()
		$('.backdrop').remove()


# Helpful functions
loadScript = (u, d) ->
	d = typeof(d) != 'undefined' ? d : ""
	$.ajax({type: "POST", url: u, data: d, dataType: "script"})

timeFromUnix = (tm) ->
	date = new Date(tm * 1000)
	return date.toLocaleTimeString()

cropImage = (img_url, img_width, img_height) ->
	return $('<div>').css({
		background: 'url(' + img_url + ')',
		backgroundSize: 'cover',
		'background-position': 'center',
		backgroundColor: '#FFF',
		width: img_width,
		height: img_height,
		display: 'inline-block'
	})

link_to = (text, url) ->
	return $('<a>').attr('href', url).html(text)
link_to_rel = (text, url) ->
	return $('<a>').attr('href', "#" + url).html(text)
link_to_span = (text) ->
	return $('<span>').addClass('clickable').html(text)

fadeInElement = (elem) ->
	$(elem).hide().fadeIn()

initKO = ->
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
			$(element).keypress ->
				if (ev.keyCode == 13)
					action = valueAccessor()
					val = bindingsAccessor().value
					val($(element).val())
					action.call(viewModel)
					return false

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
			$(element).fileupload(ko.utils.unwrapObservable(valueAccessor()))

	ko.bindingHandlers.center =
		init : (element, valueAccessor, bindingsAccessor, viewModel) ->
			setTimeout ->
					$(element).center()
				, 1

	ko.bindingHandlers.progress =
		update: (element, valueAccessor) ->
			$(element).progressbar({value : ko.utils.unwrapObservable(valueAccessor())})

	ko.bindingHandlers.placeholder =
		update: (element, valueAccessor) ->
			if ($(element).val().length > 0)
				$(element).siblings('label').hide()
			else
				$(element).siblings('label').show()

	ko.absorbModel = (data, self) ->
		for prop in data
			if (typeof(self[prop]) != "function")
				self[prop] = ko.observable(data[prop])
			else
				self[prop](data[prop])
			self.fields.pushOnce(prop)
		self.model_state(ko.modelStates.READY)

	ko.saveModel = (fields, path, callback, self) ->
		if (self.model_state() != ko.modelStates.READY)
			console.log("Save postponed.")
			return
		opts = {}
		if (fields instanceof Array)
			fields.push('id')
			for i in fields
				prop = fields[i]
				opts[prop] = self[prop]()
		else
			opts = fields
		if (self.doDelete())
			opts['_delete'] = true
		$.post(path, opts, callback)
		self.model_state(ko.modelStates.SAVING)

	ko.addFields = (fields, val, self) ->
		for i in fields
			prop = fields[i]
			if (typeof(self[prop]) != "function")
				if (val instanceof Array)
					self[prop] = ko.observableArray()
				else
					self[prop] = ko.observable(val)
			else
				self[prop](val)
			if (typeof(prop) == "string")
				self.fields.pushOnce(prop)

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
	constructor: (data, collection) ->
		@fields = []
		ko.addFields(['id'], '', this)
		@models = {}
		@events = {}
		@collection = collection
		@db_state = ko.observable({})
		@init()
		@model_state = ko.observable(0)
		@doDelete = ko.observable(false)
		@load_key = 'id'
		@load_url = "/"
		@save_url = "/"
		@uploadParams = {}
		@uploadProgress = ko.observable(0)
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
		@handleData(data || {})
	handleData : (resp) ->
		ko.absorbModel(resp, this)
		@db_state(@toJS())
	load : (id, callback)->
		opts = {}
		opts[@load_key] = id
		$.getJSON @load_url, opts, (resp) =>
			@handleData(resp.data)
			callback(resp) if callback?
		@model_state(ko.modelStates.LOADING)
	save : (fields, callback) ->
		opts = fields
		opts.push('id')
		console.log("Saving fields #{opts}")
		ko.saveModel opts, @save_url, (resp) =>
				@handleData(resp.data)
				callback(resp) if callback?
				@collection.load() if @collection?
			, this
	reset : ->
		@model_state(ko.modelStates.LOADING)
		@id('')
		@init()
		@db_state(@toJS())
		@uploadProgress(0)
		@model_state(ko.modelStates.READY)
	deleteModel : =>
		@doDelete(true)
		@save(['id'])
	toJS : =>
		obj = {}
		for prop in @fields
			obj[prop] = @[prop]()
		obj
	absorb : (model) =>
		@reset()
		@handleData(model.toJS())

class @Collection
	constructor: (opts) ->
		@opts = opts || {}
		@scope = ko.observable(@opts.scope || {})
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
				opts['scope'] = ko.toJSON(@scope())
				opts['limit'] = @limit()
				opts['page'] = @page()
				opts
			, this
		@scope = ko.intercepter @scope, (obs, prev, curr) ->
				obs(curr)
				console.log("Scope changed from #{prev} to #{curr}")
				@load()
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
		opts = {}
		opts[scp] = args
		@scope(opts)
	load : (opts)->
		@extra_params(opts.extra_params) if opts? && opts.extra_params?
		console.log("Loading items for #{@scope()}")
		$.getJSON(@path_url, @loadOptions(), @handleData)
		@model_state(ko.modelStates.LOADING)
	handleData : (resp) =>
		mapped = (new @model(item, this) for item in resp.data)
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

class @View
	init : ->
	constructor : (@name, @owner)->
		@views = {}
		@events = {}
		@is_visible = ko.observable(false)
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
		@path(path)
		@parts = @path().split('/')
	embed : ->
		console.log("Adding #{@name} to #{@owner}...")
		$(".view-#{@owner} .view-box").append("<div class='view-#{@name}' data-bind=\"visible : views.#{@name}.is_visible(), template : {name : 'view-#{@name}', data : views.#{@name}}\"></div>")
	addView : (name, view_class) ->
		@views[name] = new view_class(name, @name)
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
			@view = view
			last_view.hide() if last_view?
			view.show()
			window.onbeforeunload = @view.events.before_unload
	getViewName : (view) ->
		console.log("Name: " + view.name)
		"view-#{view.name}"

class @AppViewModel extends @View
	constructor : ->
		super('app', null)
		@path = ko.observable(null)
	route : (path) ->
		console.log("Loading path '#{path}'")
		@handlePath(path)
	setUser : (user)->
	redirectTo : (path) ->
		$.history.load(path)

appViewModel = null
overlay = null

@initApp = ->
	initKO()
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

