## EXTENSIONS
Array.prototype.indexAt = (val) ->
	for i in [0...this.length]
		if this[i] == val
			return i
	return -1
Array.prototype.includes = (val) ->
	return this.indexAt(val) != -1
Array.prototype.itemAt = (val)->
	return this.slice(val)[0]
Array.prototype.pushOnce = (item) ->
	if (!this.includes(item))
		this.push(item)
Array.prototype.remove = (item) ->
	idx = this.indexOf(item)
	this.splice(idx, 1) if idx > -1
Date.from_utc = (utc) ->
	new Date(utc * 1000)
Date.from_now = ->
	new Date()
Date.now_utc = ->
	Math.round( (new Date()).getTime() / 1000.0)
Date.prototype.to_utc = ->
	Math.round(this.getTime() / 1000.0)
Date.prototype.remove_time = ->
	this.setHours(0)
	this.setMinutes(0)
	this.setSeconds(0)
	this.setMilliseconds(0)
	return this
String.prototype.endsWith = (suffix) ->
	this.indexOf(suffix, this.length - suffix.length) != -1
String.prototype.includes = (str) ->
	this.indexOf(str) != -1
String.prototype.truncate = (val)->
	ret = this.substring(0, val)
	ret = ret + "..." if this.length > val
	return ret
String.prototype.rjust = (length, char)->
	ret = this
	while (ret.length < length)
		ret = char + ret
	return ret

History.getRelativeUrl = ->
	url = History.getState().url
	"/#{url.replace(History.getRootUrl(), '')}"

## SELECTOPTS
class @SelectOpts
	constructor : ->
		@options = []
	add : (val, str)=>
		@options.push {val : val.toString(), str : str}
		return this
	find : (val)=>
		for obj in @options
			return obj.str if (obj.val == val.toString())
		return ""

## PAGETIMER
class @PageTimer
	constructor: (func, time) ->
		@callback = func
		@frequency = time * 1000
		@t_id = -1
	start : =>
		@t_id = setInterval(@callback, @frequency)
	stop : =>
		clearInterval(@t_id)
		@t_id = -1
	isRunning : =>
		@t_id != -1
	setFrequency : (time) =>
		@stop()
		@frequency = time * 1000
		@start()
	getFrequency : =>
		return @frequency / 1000
	increasePollTime : =>
		@setFrequency( @getFrequency() + (if @getFrequency() % 5 == 0 then 9 else 1) )

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
		$(document).click ->
			Overlay.removePopovers()
Overlay.instance = new Overlay()
Overlay.closeDialog = ->
		@remove('dialog')
Overlay.add = (vm, tmp, options, cls) ->
		id = vm.name
		template = tmp
		cls = cls || ''
		options = {} if !options?
		#options['z-index'] = Overlay.instance.zindex + 10
		$('body').append("<div id='overlay-" + id + "' class='modal hide fade'><button class='close' data-bind='click : hideOverlay'>x</button><div class='content' data-bind=\"template: '" + template + "'\"></div></div>")
		#$('#overlay-' + id).css(options)
		#$('#overlay-' + id).addClass(cls)
		#$('#overlay-' + id).css({'margin-left' : -1 * $('#overlay-' + id).width() / 2})
		#$('.overlay .content').css({'max-height' : ($(window).height() - 100)})
		#$('#backdrop-' + id).click =>
			#console.log('backdrop clicked.')
			#Overlay.remove(id)
		setTimeout ->
			$('#overlay-' + id).koBind(vm)
			$('#overlay-' + id).modal('show')
			$('#overlay-' + id).on 'hidden', ->
				$('#overlay-' + id).koClean()
				$('#overlay-' + id).remove()
		, 100
		#Overlay.instance.zindex = Overlay.instance.zindex + 10

Overlay.dialog = (msg, opts) ->
		vm =
			name : 'dialog'
			message : ko.observable(msg)
			yes : opts.yes
			no : opts.no
			cancel : Overlay.remove('dialog')
		Overlay.add(vm, 'view-dialog', { width : 300 })

Overlay.notify = (msg, cls, tm) ->
		cls = cls || ''
		tm = tm || 3000
		Overlay.clearNotifications()
		$('body').prepend("<div id='notify' class='notify' style='display: none;'>" + msg + "</div>")
		if (cls)
			$('#notify').addClass(cls)
		$('#notify').slideDown 'slow', ->
			Overlay.instance.notifyTimeout = setTimeout ->
					$('#notify').fadeOut('slow')
				, tm

Overlay.clearNotifications = ->
		clearTimeout(Overlay.instance.notifyTimeout)
		$('#notify').remove()

Overlay.confirm = (msg, opts) ->
		vm =
			yes : ->
				opts.yes() if opts.yes?
				Overlay.remove('confirm')
			no : ->
				opts.no() if opts.no?
				Overlay.remove('confirm')
		$('body').prepend("<div class='backdrop' id='backdrop-confirm' style='z-index:500'></div><div id='overlay-confirm' class='confirm' style='display: none;'><div class='msg'>" + msg + "</div><div class='opts'><button class='button green' data-bind='click : yes'>yes</button><button class='button red' data-bind='click : no'>no</button></div></div>")
		$('#overlay-confirm').koBind(vm)
		$('#overlay-confirm').slideDown 'fast'

Overlay.remove = (id) ->
		$('#overlay-' + id).modal('hide')
		$('#popover-' + id).koClean().remove()

Overlay.removePopovers = ->
		$('.popover').remove()

Overlay.popover = (el, vm, tmp, opts)->
	id = vm.name
	opts.placement = opts.placement || 'bottom'
	$po = $("<div id='popover-#{id}' class='popover fade'><div class='arrow'></div><div class='popover-inner'><h3 class='popover-title'>#{opts.title}</h3><div class='popover-content' data-bind=\"template : '#{tmp}'\"></div></div></div>")
	$po.remove().css({ top: 0, left: 0, display: 'block', width: 'auto' }).prependTo(document.body)
	$po.koBind(vm)
	$po.click (ev)->
		ev.stopPropagation()

	pos = getElementPosition(el)
	actualWidth = $po[0].offsetWidth
	actualHeight = $po[0].offsetHeight
	#console.log(actualWidth + ' ' + actualHeight)
	#console.log(pos)

	switch (opts.placement)
		when 'bottom'
			tp = {top: pos.top + pos.height, left: pos.left + pos.width / 2 - actualWidth / 2}
		when 'top'
			tp = {top: pos.top - actualHeight, left: pos.left + pos.width / 2 - actualWidth / 2}
		when 'left'
			tp = {top: pos.top + pos.height / 2 - actualHeight / 2, left: pos.left - actualWidth}
		when 'right'
			tp = {top: pos.top + pos.height / 2 - actualHeight / 2, left: pos.left + pos.width}
	
	tp.display = 'block'
	$po.css(tp).addClass(opts.placement).addClass('in')


## TIMELENGTH
class @TimeLength
	constructor : (@date1, @date2)->
		@date2 = new Date() unless @date2?
	seconds : ->
		Math.floor( ( @date2.getTime() - @date1.getTime() ) / 1000 )
	minutes : ->
		Math.floor( @seconds() / 60 )
	hours : ->
		Math.floor( @seconds() / (60 * 60) )
	days : ->
		Math.floor( @seconds() / (24 * 60 * 60) )
	weeks : ->
		Math.floor( @seconds() / (24 * 60 * 60 * 7) )
	months : ->
		Math.floor( @seconds() / (24 * 60 * 60 * 31) )
	years : ->
		Math.floor( @seconds() / (24 * 60 * 60 * 365) )
	toString : ->
		val = 0
		str = ""
		if @years() > 0
			val = @years()
			str = "year"
		else if @months() > 0
			val = @months()
			str = "month"
		else if @weeks() > 0
			val = @weeks()
			str = "week"
		else if @days() > 0
			val = @days()
			str = "day"
		else if @hours() > 0
			val = @hours()
			str = "hour"
		else if @minutes() > 0
			val = @minutes()
			str = "minute"
		else if @seconds() > 0
			val = @seconds()
			str = "second"
		else
			val = 0
			str = "minutes"
		attr = str + ( if (val > 1) then "s" else "" )
		"#{val} #{attr}"
TimeLength.DAY = 86400
TimeLength.YEAR = 31536000

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

@getElementPosition = (el)->
	ret = $(el).offset()
	ret.width = el.offsetWidth
	ret.height = el.offsetHeight
	return ret

