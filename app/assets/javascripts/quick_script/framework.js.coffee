@QuickScript = {}
@QS = QuickScript

QuickScript.utils =
	buildOptions : (hash)->
		ret = []
		for key, val of hash
			ret.push {value: key, text: val}
		return ret
	renderToString : (tmpl, vm)->
		$el = $('<div>')
		$el.koBind(vm, tmpl)
		html = $el[0].innerHTML
		$el.koClean()
		return html
	pluralize : (count, single, plural)->
		if count == 1
			return "#{count} #{single}"
		else
			return "#{count} #{plural}"
	isFunction : (fn)->
		return (typeof(fn) == 'function')
	isRegularObject : (obj)->
		return obj.constructor == Object
	uuid : ->
		Math.random().toString().substring(2)
	linkify : (text)->
		exp = /(\b(https?|ftp|file):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/ig
		return text.replace(exp,"<a target='_blank' href='$1'>$1</a>")
	toUSDString : (amt) ->
		amt_usd = amt / 100.0
		"$ #{amt_usd.toFixed(2)}"
	getMouseCoords : (ev, type, opts)->
		type ||= 'absolute'
		coords = null
		if ev.originalEvent.offsetX? && ev.originalEvent.offsetY?
			coords = {x: ev.originalEvent.offsetX, y: ev.originalEvent.offsetY}
		else
			coords = {x: ev.originalEvent.layerX, y: ev.originalEvent.layerY}

		if type == 'relative'
			ts = {w: ev.currentTarget.offsetWidth, h: ev.currentTarget.offsetHeight}
			return {x: (coords.x / ts.w) * 100, y: (coords.y / ts.h) * 100}
		else
			return coords


QuickScript.log = (msg, lvl)->
	lvl ||= 1
	console.log(msg) if (QS.debug == true && lvl <= QS.log_level)
QuickScript.debug ||= true
QuickScript.log_level ||= 5
QuickScript.start_time = Date.now()
QuickScript.time = ->
	now = Date.now()
	return (now - QS.start_time) / 1000.0
QuickScript.request_headers = {}

QuickScript.includeEventable = (self)->
	self::handle = (ev, callback)->
		@_events ||= {}
		@_events[ev] ||= []
		@_events[ev].push callback
	self::trigger = (ev, data)->
		QS.log "EVENTABLE::TRIGGER : #{ev}", 5
		@_events ||= {}
		cbs = @_events[ev]
		if cbs?
			cbs.forEach (callback)->
				callback(data)


class @Model
	init : ->
	extend : ->
	constructor: (data, collection, opts) ->
		@_uuid = QS.utils.uuid()
		@fields = []
		@submodels = []
		@is_submodel = false
		@addFields(['id'], '')
		#@events = {}
		@adapter = if @initAdapter? then @initAdapter() else null
		@collection = collection
		@db_state = ko.observable({})
		@errors = ko.observable({})
		@errors.extend({errors: true})
		@model_state = ko.observable(0)
		@saveProgress = ko.observable(0)
		if opts?
			@is_submodel = opts.is_submodel
		@extend()
		@init()
		@addComputed 'is_ready', ->
			@model_state() == ko.modelStates.READY
		@addComputed 'is_loading', ->
			@model_state() == ko.modelStates.LOADING
		@addComputed 'is_saving', ->
				@model_state() == ko.modelStates.SAVING
		@addComputed 'is_editing', ->
				@model_state() == ko.modelStates.EDITING
		@addComputed 'is_new', ->
				@id() == ''
		@addComputed 'is_dirty', ->
				JSON.stringify(@db_state()) != JSON.stringify(@toJS())
		@addComputed 'has_errors', ->
				@errors.any()
		@handleData(data || {})
	addFields : (fields, def_val) ->
		ko.addFields fields, def_val, this
	addComputed : (field, fn_opts) ->
		ko.addComputed field, fn_opts, this
	addSubModel : (field_name, class_name, nested) ->
		nested ||= false
		if nested == true || @is_submodel == false
			ko.addSubModel field_name, class_name, this
		@submodels[field_name] = class_name if typeof(field_name) == "string"
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
				callback({meta : 500, error : 'An error occurred', data : {errors : ['An error occurred']}}) if callback?
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
				callback({meta : 500, error : 'An error occurred', data : {errors : ['An error occurred']}}) if callback?
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
					if val?
						obj[prop] = val
					else
						obj[prop] = ''
		obj
	toJSON : (flds)=>
		JSON.stringify(@toJS(flds))
	getClass : =>
		@constructor
	toClone : =>
		m = new(@getClass())
		m.absorb(this)
		return m
	checkDirty : (prop)=>
		@db_state()[prop] != @[prop]()
	absorb : (model) =>
		@reset()
		@handleData(model.toJS())
Model.includeCollection = (self)->
	self ||= this
	self.Collection = class extends Collection
		constructor : (opts)->
			super(opts)
			@adapter = self.Adapter
			@model = self
Model.includeAdapter = (adapter, self)->
	self ||= this
	if !adapter.save? && !adapter.load?
		adapter.type ||= ModelAdapter
		adapter = new adapter.type(adapter)
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
		@items.subscribe @updateViews
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
				#console.log("Scope changed from #{prev} to #{curr}")
				#@load()
			, this
		@hasItems = ko.dependentObservable ->
				@items().length > 0
			, this
		@has_items = ko.computed ->
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
	updateViews : (items)=>
		view_cls = @view_model()
		view_owner = @view_owner()
		ra = items
		ca = @views()
		max_len = Math.max(ra.length, ca.length)

		# cache views by model
		mh = {}
		ca.forEach (view)->
			mh[view.model._uuid] = view
		#QS.log mh

		# iterate possible positions
		if max_len > 0
			for idx in [(max_len-1)..0]
				# here we will check if any of the views in the current list
				# have models that match ones in the new list
				rm = ra[idx]
				cm = if ca[idx]? then ca[idx].model else null

				if !rm?
					# item has been deleted
					ca.splice(idx, 1)
				else
					# models aren't the same
					# check if another view in list has model
					view_name = "view-#{rm.id()}"
					same_view = mh[rm._uuid]
					if same_view?
						ca[idx] = same_view
					else
						ca[idx] = new view_cls(view_name, view_owner, rm)
		@views.valueHasMutated()
	setView : (view_model, view_owner) =>
		@view_model(view_model)
		@view_owner(view_owner)
	_load : (scope, op, callback)->
		#console.log("Loading items for #{scope}")
		op ||= Collection.REPLACE
		reqid = ++@_reqid
		opts = @loadOptions()
		opts.scope = if (scope instanceof Array) then scope else JSON.stringify(scope)
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
	load : (scope, opts)=>
		opts = {callback: opts} if (!opts?) || (opts instanceof Function)
		@reset() unless opts.reset? && !opts.reset
		@scope(scope) if scope?
		@_load(@scope(), Collection.REPLACE, opts.callback)
	update : (callback)=>
		@_load(@scope(), Collection.UPDATE, callback)
	insert : (scope, callback)->
		@_load(scope, Collection.INSERT, callback)
	append : (scope, callback)->
		@_load(scope, Collection.APPEND, callback)
	handleData : (resp, op) =>
		#QS.log "COLLECTION::HANDLE_DATA : Starting (#{QS.time()}).", 3
		models = []
		views = []
		op ||= Collection.REPLACE
		cls = @view_model()
		#if (op == Collection.REPLACE) || (op == Collection.UPDATE)
			#@items([]); @views([])
		if op == Collection.UPDATE
			curr_a = @items()
			curr_len = @items().length
			new_a = resp
			new_len = resp.length
			max_len = Math.max(curr_len, new_len)

			# build temp id hash
			id_h = {}
			curr_a.forEach (itm)->
				id_h[itm.id()] = itm

			# iterate possible positions
			if max_len > 0
				for idx in [(max_len-1)..0]
					c_el = curr_a[idx]
					c_id = if c_el? then c_el.id() else null
					r_el = new_a[idx]
					r_id = if r_el? then r_el.id else null

					if c_id == r_id
						# absorb if ids are the same
						c_el.handleData(r_el)
					else if r_id == null
						# this position is now empty, need to delete
						curr_a.splice(idx, 1)
					else
						# item ids aren't the same
						#	find item in temp hash
						same_itm = id_h[r_id]
						if same_itm?
							# replace old with new
							curr_a[idx] = same_itm
							curr_a[idx].handleData(r_el)
						else
							# item not found, must be new
							curr_a[idx] = new @model(r_el, this)

			@items.valueHasMutated()

		else
			for item, idx in resp
				model = new @model(item, this)
				models.push(model)
				views.push(new cls("view-#{model.id()}", @view_owner(), model))

			#QS.log "COLLECTION::HANDLE_DATA : Finished building data #{QS.time()}.", 3
			if !op? || op == Collection.REPLACE
				@items(models)
				#@views(views)
			else if op == Collection.INSERT
				@items(models.concat(@items())) if models.length > 0
				#@views(views.concat(@views()))
			else if op == Collection.APPEND
				@items(@items().concat(models)) if models.length > 0
				#@views(@views().concat(views))
		@model_state(ko.modelStates.READY)
	handleItemData : (data)=>
		item = @getItemById(data.id)
		item.handleData(data) if item?
		return item
	nextPage : =>
		@page(@page() + 1)
		@update()
	prevPage : =>
		@page(@page() - 1)
		@update()
	hasItems : =>
		@items().length > 0
	length : =>
		@items().length
	addItem : (item, notify)->
		notify ||= true
		item.collection = this
		cls = @view_model()
		view = new cls("view-#{item.id()}", @view_owner(), item)
		@items().push(item)
		#@views().push(view)
		@items.valueHasMutated() if notify
		#@views.valueHasMutated() if notify
		return view
	removeItem : (idx, notify)->
		notify ||= true
		@items().splice(idx, 1)
		#@views().splice(idx, 1)
		@items.valueHasMutated() if notify
		#@views.valueHasMutated() if notify
	moveItem : (from, to, notify)->
		notify ||= true
		@items().splice(to, 0, @items().splice(from, 1)[0])
		#@views().splice(to, 0, @views().splice(from, 1)[0])
		@items.valueHasMutated() if notify
		#@views.valueHasMutated() if notify
	getItemById : (id)->
		list = @items().filter ((item)=> item.id() == id)
		ret = if list.length > 0 then list[0] else null
	getViewById : (id)->
		list = @views().filter ((view)=> view.model.id() == id)
		ret = if list.length > 0 then list[0] else null
	getIndexById : (id)->
		idx = 0
		for item in @items()
			return idx if item.id() == id
			idx = idx + 1
		return null
	nthViews : (n, offset) ->
		@views().filter (el, i)->
			(i-offset) % n == 0
	removeDuplicates : ->
		ids = []
		@items().forEach (item, idx, array)=>
			if ids.includes(item.id())
				@items.splice(idx, 1)
				#@views.splice(idx, 1)
			else
				ids.push(item.id())
	removeIf : (callback)->
		@items().forEach (item, idx, array)=>
			if callback(item, idx)
				@items.splice(idx, 1)
				#@views.splice(idx, 1)
	removeItemById : (id)->
		@removeIf (item)=>
			item.id() == id
	getTemplate : ->
		@template()
	reset : ->
		@page(1)
		@items([])
		#@views([])
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
	QuickScript.includeEventable(this)
	init : ->
	constructor : (@name, @owner, @model, @opts)->
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
		@onShown() if @onShown?
	hide : ->
		for name, view of @views
			view.hide()
		@is_visible(false)
		@onHidden() if @onHidden?
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
	addFields : (fields, def) =>
		ko.addFields(fields, def, this)
	addComputed : (field, fn_opts) ->
		ko.addComputed field, fn_opts, this
	validate_for : (field, fn, msg) =>
		ko.validate_for(field, fn, msg, this)
	validate_fields : (fields, fn) =>
		ko.validate_fields(fields, fn, this)
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
			view.load.apply(view, args[1..])
			window.onbeforeunload = @view.events.before_unload
		else
			@view.reload.apply(@view, args[1..])
		view.show()
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

class @ModelAdapter
	constructor : (opts)->
		@save_url = null
		@load_url = null
		@index_url = null
		@host = ModelAdapter.host
		@notifier = null
		@event_scope = null
		for prop,val of opts
			@[prop] = val
	setNotifier : (notif, scope)->
		@notifier = notif
		@event_scope = scope
	load : (opts)->
		opts.type = 'GET'
		opts.url = @load_url
		opts.data["_cv"] = Date.now() if opts.data?
		opts.event_name = "updated"
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
		opts.event_name = "updated"
		@send opts
	send : (opts)->
		ModelAdapter.send(@host, opts, this)
	delete : (opts)->
		opts.type = 'DELETE'
		opts.url = @save_url
		opts.event_name = "deleted"
		@send opts
	add_method : (fn_name, fn)->
		@[fn_name] = fn.bind(this)
	route_method : (fn_name, url, http_m)->
		http_m ||= 'POST'
		@add_method fn_name, (opts)->
			opts.url = url
			opts.type = http_m
			@send opts
			
ModelAdapter.send = (host, opts, self)->
	def_err_fn = ->
		opts.success({meta : 500, error : 'An error occurred.', data : {errors : ['An error occurred.']}})
	success_fn = opts.callback || opts.success
	opts.type = 'POST' if !opts.type?
	opts.url = host + opts.url
	opts.error = def_err_fn unless opts.error?
	opts.success = (resp)->
		success_fn(resp) if success_fn?
		if self.notifier? && self.event_scope? && opts.event_name? && resp.meta == 200
			self.notifier.trigger "#{self.event_scope}.#{opts.event_name}", resp.data
	$.ajax_qs opts
ModelAdapter.host = '/api/'

class @AccountAdapter
	constructor : (opts)->
		@login_url = "/account/login"
		@logout_url = "/account/logout"
		@register_url = "/account/register"
		@enter_code_url = "/account/enter_code"
		@reset_url = "/account/reset"
		@activate_url = "/account/activate"
		@save_url = "/account/save"
		@load_url = "/account"
		@login_key = "email"
		@password_key = "password"
		@host = ModelAdapter.host
		for prop,val of opts
			@[prop] = val
	login : (opts)->
		opts.url = @login_url
		@send opts
	logout : (opts)->
		opts.url = @logout_url
		@send opts
	register : (opts)->
		opts.url = @register_url
		@send opts
	sendInviteCode : (opts)->
		opts.url = @enter_code_url
		@send opts
	save : (opts) ->
		opts.url = @save_url
		@send opts
	load : (opts) ->
		opts ||= {}
		opts.type = 'GET'
		opts.url = @load_url
		@send opts
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
		ModelAdapter.send(@host, opts, this)
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
		@redirect_on_login = ko.observable(null)
		LocalStore.get 'app.redirect_on_login', (val)=>
			@redirect_on_login(val)
			@redirect_on_login.subscribe (val)=>
				LocalStore.save 'app.redirect_on_login', val
		ko.addTemplate "viewbox", """
				<div data-bind='foreach : viewList()'>
					<div data-bind="fadeVisible : is_visible(), template : { name : getViewName, afterRender : afterRender, if : is_visible() }, attr : { id : templateID, 'class' : templateID }, bindelem : true"></div>
				</div>
			"""
		ko.addTemplate "viewbox-slide", """
				<div class="view-slider" data-bind="style : {width : transition.opts.width + 'px', height : transition.opts.height + 'px'}, carousel : task">
					<div data-bind='foreach : viewList()'>
						<div class="slide-item" data-bind="template : { name : getViewName }, attr : {id : templateID, class : 'slide-item slide-item-' + $index()}, css : {}, style : {width : owner.transition.opts.width + 'px', height : owner.transition.opts.height + 'px'}, bindelem : true"></div>
					</div>
				</div>
			"""
		@configure()
		@account_model ||= Model
		@current_user = new @account_model()
		@is_logged_in = ko.computed ->
				!@current_user.is_new()
			, this
		super('app', null)
	configure : ->
	route : ->
		path = History.getRelativeUrl()
		console.log("Loading path '#{path}'")
		@setTitle(@name, true)
		@previous_path(@path())
		@path_parts = path.split('/')
		@path_parts.push('') unless @path_parts[@path_parts.length-1] == ''
		@path(path)
		@handlePath(path)
	handlePath : (path) ->
	setUser : (data)->
		console.log(data)
		@current_user.handleData(data) if data != null
	loadUser : (adapter)->
		adapter.load
			loading : @is_loading
			callback : (resp)=>
				@setUser(resp.data) if resp.meta == 200
				@route()
	redirectTo : (path, replace, opts) ->
		opts ||= {}
		@redirect_on_login(opts.on_login) if opts.on_login?
		if replace? && replace == true
			History.replaceState(null, null, path)
		else
			History.pushState(null, null, path)
	loginTo : (path, user_data, opts)->
		@current_user.handleData(user_data)
		if @redirect_on_login() != null
			@redirectTo(@redirect_on_login())
			@redirect_on_login(null)
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
	app.setUser(current_user) if current_user?

	# navigation
	History.Adapter.bind window, 'statechange', ->
		app.route()

	# layout bindings
	$('body').koBind(app)
	app.afterRender()

	# override links
	$('body').on 'click', 'a', ->
		if this.href.includes(History.getRootUrl())
			History.pushState null, null, this.href
			return false
		else
			return true

	app.route()
	return app

