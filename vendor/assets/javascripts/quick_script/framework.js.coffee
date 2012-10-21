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

	# buttonStatus - [is_loading, ready_str, loading_str, icon_classes]
	ko.bindingHandlers.buttonStatus =
		update : (element, valueAccessor) ->
			opts = ko.utils.unwrapObservable(valueAccessor())
			if opts[0]
				$(element).html(opts[2])
				$(element).attr('disabled', 'true')
			else
				if opts[3]?
					txt = "<i class='#{opts[3]}'></i> #{opts[1]}"
				else
					txt = opts[1]
				$(element).html(txt)
				$(element).removeAttr('disabled')

	# labelStatus - [list, none_str, loading_str]
	ko.bindingHandlers.listStatus =
		init : (element, valueAccessor) ->
			opts = ko.utils.unwrapObservable(valueAccessor())
			if opts[0].is_loading()
				$(element).html(opts[2])
				$(element).show()
			else
				if opts[0].hasItems()
					$(element).hide()
				else
					$(element).show()
					$(element).html(opts[1])
		update : (element, valueAccessor) ->
			opts = ko.utils.unwrapObservable(valueAccessor())
			opts[0].is_loading.subscribe ->
				if opts[0].is_loading()
					$(element).html(opts[2])
					$(element).show()
				else
					if opts[0].hasItems()
						$(element).hide()
					else
						$(element).show()
						$(element).html(opts[1])

	ko.bindingHandlers.viewOptions =
		update : (element, valueAccessor) ->
			$(element).empty()
			opts = ko.utils.unwrapObservable(valueAccessor())
			for view in opts[0]
				$(element).append("<option value='#{opts[2](view)}'>#{opts[1](view)}</option>")
			if opts[3]?
				$(element).prepend("<option>#{opts[3]}</option>")

	ko.bindingHandlers.handleEnter =
		init : (element, valueAccessor, bindingsAccessor, viewModel) ->
			$(element).keypress (ev)->
				if (ev.keyCode == 13 && !ev.shiftKey)
					action = valueAccessor()
					val = bindingsAccessor().value
					val($(element).val())
					action.call(viewModel)
					return false

	ko.bindingHandlers.touchstart =
		init : (element, valueAccessor, bindingsAccessor, viewModel) ->
			element.addEventListener('touchstart', valueAccessor().bind(viewModel))

	ko.bindingHandlers.validate =
		update : (element, valueAccessor) ->
			opts = valueAccessor()
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

	ko.bindingHandlers.checkedInt =
		init: (element, valueAccessor, allBindingsAccessor) ->
			observable = valueAccessor()
			interceptor = ko.computed
				read: ->
					return observable().toString()
				write: (newValue) ->
					observable(+newValue)
				owner: this
			ko.applyBindingsToNode(element, { checked: interceptor })

	ko.bindingHandlers.untabbable =
		update : (element, valueAccessor, bindingsAccessor, viewModel) ->
			if (valueAccessor())
				$(element).find('iframe, input, textarea, a, iframe').attr('tabIndex', -1)
			else
				$(element).find('input, textarea, a, iframe').removeAttr('tabIndex')

	ko.bindingHandlers.carousel =
		init : (element, valueAccessor, bindingsAccessor, viewModel) ->
			setTimeout ->
				idx = viewModel.getViewBoxIndex(viewModel.task())
				new_el = $(element).find('.slide-item-' + idx).first()
				#new_el.addClass('active')
			, 0
		update : (element, valueAccessor, bindingsAccessor, viewModel) ->
				opts = viewModel.transition.opts
				if viewModel.task() != null
					setTimeout ->
						idx = viewModel.getViewBoxIndex(viewModel.task())
						console.log(viewModel.name + ': updating slider to ' + idx)
						old_idx = opts.slide_index()
						new_el = $(element).find('.slide-item-' + idx).first()
						old_el = $(element).find('.slide-item-' + old_idx).first()
						if idx > old_idx
							new_el.addClass('next')
							new_el[0].offsetWidth if new_el[0]?
							old_el.addClass('left')
							new_el.addClass('left')
						else
							new_el.addClass('prev')
							new_el[0].offsetWidth if new_el[0]?
							old_el.addClass('right')
							new_el.addClass('right')
						setTimeout ->
							new_el.removeClass('next left prev right')
							old_el.removeClass('next left prev right')
							old_el.removeClass('active')
							new_el.addClass('active')
						, 600
						opts.slide_index(idx)
					, 0

	ko.bindingHandlers.bindelem =
		init : (element, valueAccessor, bindingsAccessor, viewModel) ->
			viewModel.element = element

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
			$(element).children('li').each (idx, el)->
				tab_id = $(el)[0].id
				$(el).click ->
					valueAccessor()(tab_id)
		update : (element, valueAccessor, bindingsAccessor, viewModel) ->
			sel_tab = ko.utils.unwrapObservable(valueAccessor())
			$(element).children('li').removeClass('active')
			$(element).children("li##{sel_tab}").addClass('active')
	ko.bindingHandlers.tab_views =
		update : (element, valueAccessor, bindingsAccessor, viewModel) ->
			sel_tab = ko.utils.unwrapObservable(valueAccessor())
			$(element).children('div').addClass('hidden').removeClass('active')
			$(element).children("div##{sel_tab}").addClass('active').removeClass('hidden')

	ko.bindingHandlers.calendar =
		init : (element, valueAccessor, bindingsAccessor, viewModel) ->
			console.log('calendar init')
			$(element).fullCalendar('destroy')
			opts = $.extend({}, ko.utils.unwrapObservable(valueAccessor()))
			$(element).fullCalendar(opts)
			viewModel.calendar = $(element).fullCalendar.bind($(element))

	ko.bindingHandlers.center =
		init : (element, valueAccessor, bindingsAccessor, viewModel) ->
			fn = ->
				setTimeout ->
						$(element).center()
					, 1
			viewModel.task.subscribe(fn)
			viewModel.is_visible.subscribe(fn)

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
			$(element).tooltip
				placement: opts.placement || 'bottom'
				delay: opts.delay || 0
				title: ->
					ko.utils.unwrapObservable(opts.content)

	# popover : {template : <tmp>, placement : <pos>}
	ko.bindingHandlers.popover =
		init : (element, valueAccessor, bindingsAccessor, viewModel) ->
			opts = valueAccessor()
			$(element).click ->
				Overlay.popover element, viewModel, opts.template, opts

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
	
	ko.validate_for = (field, fn, msg, self) ->
		self.validations = {} unless self.validations?
		self.validations[field] = [] unless self.validations[field]?
		self.validations[field].push {test : fn.bind(self), msg : msg}
		self[field].is_valid = ko.computed ->
			valid = true
			for val_obj in self.validations[field]
				valid &&= val_obj.test(self[field]())
			valid
		, self unless self[field].is_valid?


	ko.validate_fields = (fields, fn, self) ->
		msgs = []
		for field in fields
			for val_obj in self.validations[field]
				if !val_obj.test(self[field]())
					msgs.push val_obj.msg
		fn(msgs)

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
	ko.modelStates.UPDATING = 7
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
				opts.error(req.status) if opts.error?
			opts.loading(false) if opts.loading?
	req.upload.addEventListener('error', opts.error) if opts.error?
	if opts.progress?
		req.upload.addEventListener 'progress', (ev)->
			opts.progress(ev, Math.floor( ev.loaded / ev.total * 100 ))
	req.open opts.type, opts.url, true
	req.setRequestHeader 'X-CSRF-Token', jQuery.CSRF_TOKEN
	opts.loading(true) if opts.loading?
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

class @FileModel extends @Model
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
	load : (scope, callback)->
		@reset()
		@scope(scope) if scope?
		@_load(@scope(), Collection.REPLACE, callback)
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
		if op == Collection.REPLACE
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
		opts.data["_cv"] = Date.now() if opts.data?
		$.getJSON (@host + @load_url), opts.data, (resp)->
			opts.success(resp)
	index : (opts)->
		opts.data["_cv"] = Date.now() if opts.data?
		$.getJSON (@host + (@index_url || @load_url)), opts.data, (resp)->
			opts.success(resp)
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
		$.ajax
			type : 'DELETE'
			url : @host + @save_url
			data : opts.data
			success : opts.success
			error : opts.error
	add_method : (fn_name, fn)->
		@[fn_name] = fn.bind(this)
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
		opts.url = @host + @login_url
		opts.data[@login_key] = username
		opts.data[@password_key] = password
		@send opts
	logout : (opts)->
		opts.data = {}
		opts.url = @host + @logout_url
		@send opts
	register : (data_opts, opts)->
		opts.data = data_opts
		opts.url = @host + @register_url
		@send opts
	sendInviteCode : (code, opts)->
		opts.data = {code : code}
		opts.url = @host + @enter_code_url
		@send opts
	save : (data_opts, opts) ->
		opts.data = data_opts
		opts.url = @host + @save_url
		@send opts
	load : (opts) ->
		opts ||= {}
		$.ajax_qs
			type : 'POST'
			url : @host + @load_url
			data : opts.data
			progress : opts.progress
			success : opts.success
			error : opts.error
	resetPassword : (login, opts)->
		opts.data = {}
		opts.data[@login_key] = login
		opts.url = @host + @reset_url
		@send opts
	activate: (token, opts)->
		opts.data = {token : token}
		opts.url = @host + @activate_url
		@send opts
	send : (opts)->
		ModelAdapter.send(@host, opts)
	delete : (opts)->
		$.ajax_qs
			type : 'DELETE'
			url : @host + opts.url
			data : opts.data
			progress : opts.progress
			success : opts.success
			error : opts.error
	add_method : (fn_name, fn)->
		@[fn_name] = fn.bind(this)

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


class @AppView extends @View
	constructor : (user_model)->
		@app = this
		@path = ko.observable(null)
		@previous_path = ko.observable(null)
		@path_parts = []
		ko.addTemplate "app-view", """
				<div data-bind='foreach : viewList()'>
					<div data-bind="fadeVisible : is_visible(), template : { name : getViewName, afterRender : afterRender}, attr : { id : templateID}, bindelem : true"></div>
				</div>
			"""
		ko.addTemplate "app-slide", """
				<div class="view-slider" data-bind="style : {width : transition.opts.width + 'px', height : transition.opts.height + 'px'}, carousel : task">
					<div data-bind='foreach : viewList()'>
						<div class="slide-item" data-bind="template : { name : getViewName }, attr : {id : templateID, class : 'slide-item slide-item-' + $index()}, css : {}, style : {width : owner.transition.opts.width + 'px', height : owner.transition.opts.height + 'px'}, bindelem : true"></div>
					</div>
				</div>
			"""
		@current_user = new @account_model()
		@is_logged_in = ko.dependentObservable ->
				!@current_user.is_new()
			, this
		super('app', null)
	route : (path) ->
		console.log("Loading path '#{path}'")
		@previous_path(@path())
		@path(path)
		@path_parts = @path().split('/')
		@handlePath(path)
	handlePath : (path) ->
	setUser : (data)->
		console.log(data)
		@current_user.handleData(data) if data != null
	redirectTo : (path) ->
		History.pushState(null, null, path)
	runLater : (callback)->
		setTimeout callback, 10

@initApp = ->
	appViewModel = @appViewModel

	appViewModel.setUser(@CURRENT_USER)

	# navigation
	History.Adapter.bind window, 'statechange', ->
		appViewModel.route(History.getRelativeUrl())

	# layout bindings
	$('body').koBind(appViewModel)
	appViewModel.afterRender()

	# override links
	$('a').live 'click', ->
		if this.href.includes(History.getRootUrl())
			History.pushState null, null, this.href
			return false
		else
			return true

	appViewModel.route(History.getRelativeUrl())

