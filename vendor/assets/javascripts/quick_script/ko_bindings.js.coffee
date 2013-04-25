QuickScript.initKO = ->
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

	ko.bindingHandlers.dim =
		init : (element, valueAccessor) ->
			shouldDim = ko.utils.unwrapObservable(valueAccessor())
			if shouldDim then $(element).css({opacity : 0.3}) else $(element).css({opacity: 1.0})
		update : (element, valueAccessor) ->
			shouldDim = ko.utils.unwrapObservable(valueAccessor())
			if shouldDim then $(element).animate({opacity : 0.3}) else $(element).animate({opacity: 1.0})

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
			opts = {list : opts[0], empty_str : opts[1], loading_str : opts[2]} if opts instanceof Array
			fn = ->
				if opts.list.is_loading()
					if opts.loading_img?
						$(element).html("<img src='#{opts.loading_img}'/>")
					else
						$(element).html(opts.loading_str)
					$(element).show('fast')
				else
					if opts.list.hasItems()
						$(element).hide('fast')
					else
						$(element).show()
						$(element).html(opts.empty_str)
			#fn()
			opts.list.is_loading.subscribe(fn)

	# viewOptions - [views, view_string_fn, view_val_fn, default_str (optional)]
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

	ko.bindingHandlers.handleTab =
		init : (element, valueAccessor, bindingsAccessor, viewModel) ->
			$(element).keydown (ev)->
				if (ev.keyCode == 9 && !ev.shiftKey)
					action = valueAccessor()
					val = bindingsAccessor().value
					val($(element).val())
					action.call(viewModel)
					return false

	ko.bindingHandlers.selected =
		update : (element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) ->
			selected = ko.utils.unwrapObservable(valueAccessor())
			element.select() if selected

	ko.bindingHandlers.touchstart =
		init : (element, valueAccessor, bindingsAccessor, viewModel) ->
			element.addEventListener('touchstart', valueAccessor().bind(viewModel))

	ko.bindingHandlers.validate =
		update : (element, valueAccessor, bindingsAccessor, viewModel) ->
			opts = valueAccessor()
			test_fn = bindingsAccessor().value.is_valid
			err_css = 'field_invalid'
			ok_css = 'field_valid'
			if test_fn()
				$(element).removeClass(err_css)
				$(element).addClass(ok_css)
			else
				$(element).removeClass(ok_css)
				$(element).addClass(err_css)
				#opts.on_err() if opts.on_err?

	ko.bindingHandlers.allowChars =
		update : (element, valueAccessor, bindingsAccessor, viewModel) ->
			reg = new RegExp(valueAccessor(), 'g')
			$(element).keyup (ev)->
				if this.value.match(reg)
					this.value = this.value.replace(reg, '')

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
	
	ko.bindingHandlers.loadingOverlay =
		init : (element, valueAccessor) ->
			$(element).css({'position' : 'relative'})
		update : (element, valueAccessor) ->
			is_loading = ko.utils.unwrapObservable(valueAccessor())
			#loading_text = ko.utils.unwrapObservable(valueAccessor()[1])
			if is_loading
				$(element).prepend("<div class='loading-overlay'><img src='/assets/ajax-loader.gif'/></div>")
			else
				$(element).children('.loading-overlay').fadeOut()

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
	
	ko.bindingHandlers.datepicker =
		init : (element, valueAccessor) ->
			obs = valueAccessor()
			$(element).datepicker
				onClose : (dateText, inst)->
					obs(dateText)

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
			self[field] = new model({}, self, {is_submodel : true})
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
	koBind : (viewModel, tmpl) ->
		this.each ->
			$(this).koClean()
			$(this).attr('data-bind', "template : '#{tmpl}'") if tmpl?
			ko.applyBindings(viewModel, this)
	koClean : ->
		this.each ->
			$(this).removeAttr('data-bind')
			ko.cleanNode(this)

if SupportManager.hasFormData()
	jQuery.ajax_qs = (opts)->
		data = new FormData()
		req = new XMLHttpRequest()
		url = opts.url
		if opts.type == "GET"
			url = url + "?"
			first = true
			for key, val of opts.data
				if val instanceof Array
					for aval in val
						url = url + "#{key}#{escape('[]')}=#{escape(aval)}&"
				else
					url = url + "#{key}=#{escape(val)}&"
			url = url.substring(0, url.length - 1)
		else
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
		req.open opts.type, url, true
		req.setRequestHeader 'X-CSRF-Token', jQuery.CSRF_TOKEN
		opts.loading(true) if opts.loading?
		req.send(data)
		return req
else
	# IE compliant
	jQuery.ajax_qs = (opts)->
		#data = new FormData()
		req = new XMLHttpRequest()
		url = opts.url
		# build data
		data_s = ''
		for key, val of opts.data
			if val instanceof Array
				for aval in val
					data_s = data_s + "#{key}#{escape('[]')}=#{escape(aval)}&"
			else
				data_s = data_s + "#{key}=#{escape(val)}&"
		data_s = data_s.substring(0, data_s.length - 1)
		if opts.type == "GET"
			url = url + "?" + data_s
		req.onreadystatechange = (ev)->
			if req.readyState == 4
				if req.status == 200
					resp = eval("(" + req.responseText + ")")
					opts.success(resp)
				else
					opts.error(req.status) if opts.error?
				opts.loading(false) if opts.loading?
		###
		req.upload.addEventListener('error', opts.error) if opts.error?
		if opts.progress?
			req.upload.addEventListener 'progress', (ev)->
				opts.progress(ev, Math.floor( ev.loaded / ev.total * 100 ))
		###
		req.open opts.type, url, true
		req.setRequestHeader 'X-CSRF-Token', jQuery.CSRF_TOKEN
		req.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded')
		opts.loading(true) if opts.loading?
		req.send(data_s)
		return req

