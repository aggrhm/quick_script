
Modal = jQuery.fn.modal.Constructor

Modal.prototype.basic_show = Modal.prototype.show

Modal.prototype.show = (_relatedTarget)->
	self = this
	this.basic_show(_relatedTarget)
	# update z-index
	idx = $('.modal.in').length
	this.$backdrop.css('z-index', 1030 + (10 * idx))
	this.$element.css('z-index', 1040 + (10 * idx))

	if this.options.attentionAnimation?
		anim = this.options.attentionAnimation
		this.$element.on 'click.dismiss.modal', (ev)->
			return if ev.target != ev.currentTarget
			console.log 'handling click'
			self.$element.removeClass("animated #{anim}")

			setTimeout ->
				self.$element.addClass("animated #{anim}")
			, 10
