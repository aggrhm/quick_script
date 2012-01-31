## EXTENSIONS
Array.prototype.indexAt = (val) ->
	for i in [0...this.length]
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
		$('.backdrop').click =>
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

class TimeLength
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
	years : ->
		Math.floor( @seconds() / (24 * 60 * 60 * 365) )
	toString : ->
		if @years() > 1
			"#{@years()} years"
		else if @weeks() > 1
			"#{@weeks()} weeks"
		else if @days() > 1
			"#{@days()} days"
		else if @hours() > 1
			"#{@hours()} hours"
		else if @minutes() > 1
			"#{@minutes()} minutes"
		else
			"#{@seconds()} seconds"

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

