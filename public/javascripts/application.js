// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

(function($){
	$.fn.maxChar = function(limit, options) {


		// Define default settings and override w/ options.
		settings = jQuery.extend({
			debug: false,
			indicator: 'indicator',
			label: '',
			pluralMessage:' remaining',
			rate: 200,
			singularMessage: ' remaining',
			spaceBeforeMessage: ' ',
			truncate: false
		}, options);

		// Get maxChar target element.
		var target = $(this); // Must get target first, since it is used in setting other local variables.

		// Get settings.
		var debug = settings.debug;
		var indicatorId = settings.indicator;
		var label = settings.label;
		var pluralMessage = settings.pluralMessage;
		var rate = settings.rate;
		var singularMessage = settings.singularMessage;
		var spaceBeforeMessage = settings.spaceBeforeMessage;
		var truncate = settings.truncate;

		// Set additional local variables.
		var currentMessage = ''; // Current message to display to the user.
		var indicator = getIndicator(indicatorId); // Element to display count, messages and label.
		var limit = limit; // Character limit.
		var remaining = limit; // Characters remaining.
		var timer = null; // Timer to run update.

		// Initialize on page ready.
		if(label) {
			indicator.text(label);
		} else {
			// Call update once on code initialization to update view if text is already in textarea,
			// eg, if user relaoads page or hits back button and form textarea retains previoulsy entered text.
			update(limit);
		}

		// When user focuses on the target element, do the following.
		$(this).focus(function(){
			if(timer == null) {
				if(label) {
					indicator.fadeOut(function(){indicator.text('')}).fadeIn(function(){start()});
				} else {
					start();
				}
			}
		});

		// When user removes focus from the target element, do the following.
		$(this).blur(function() {
			// Stop timer that updates count and the indicator message.
			stop();
			// Update view.
			if(label) {
				indicator.fadeOut(function(){indicator.text(label)}).fadeIn();
			}
		});

		function getIndicator(id){
			// Get indicator element in the dom.
			var indicator = $('#'+id);
			// If indicator element does not already exist in the dom, create it.
			if(indicator.length == 0) {
				target.after(spaceBeforeMessage + '<span id="'+id+'"></span>');
				indicator = $('#'+id)
			}
			// Return reference to indicator element.
			return indicator;
		}

		// Create helper functions.
		function log(message) {
			// Display
			if(debug) {
				try {
					if(console) {
						console.log(message);
					}
				} catch(e) {
					// Do nothing on error.
				}
			}
		}

		// Start the timer that updates indicator.
		function start() {
			timer = setInterval(function(){update(limit)}, rate);
		}

		// Stop the timer that updates the indicator.
		function stop() {
			if(timer != null) {
				clearInterval(timer);
				timer = null;
			}
		}

		// Truncate submitted value down to limit on form submit.
		if(truncate) {
			var form_id = '#' + $(this).closest("form").attr("id");
			$(form_id).submit(function(){
				target.val(target.val().slice(0,limit));
			});
		}

		// Update the indicator.
		function update(limit){
			var remaining = limit - target.val().length;
			// Update remaining count and message.
			if(remaining == 1) {
				currentMessage = remaining + singularMessage;
			} else {
				currentMessage = remaining + pluralMessage;
			}
			// Update indicator.
			indicator.text(currentMessage);
			log(currentMessage);
		}
	};
})(jQuery);

(function($){
	$.fn.multicomplete = function(opt) {
		var $t = $(this);
		// When menu item is selected and TAB is pressed, focus should remain on current element to allow adding more values
		$t.bind('keydown', function(e) {
			if ($t.data('autocomplete').menu.active && e.keyCode == $.ui.keyCode.TAB) {
				e.preventDefault();
			}
		});

		// Call autocomplete() with our modified select/focus callbacks
		$t.autocomplete($.extend(opt,{
			// When a selection is made, replace everything after the last "," with the selection instead of replacing everything
			select: function(event,ui) {
				this.value = this.value.replace(/[^,]+$/,(this.value.indexOf(',') != -1 ?' ':'')+ui.item.value ); // + ', ');
				return false;
			},
			// Disable replacing value on focus
			focus: function(){return false;}
		}));

		// Get the "source" callback that jQuery-UI prepared
		var $source = $t.data('autocomplete').source;

		// Modify the source callback to change request.term to everything after the last ",", than delegate to $source
		$t.autocomplete('option', 'source', function(request, response) {
			request.term = request.term.match(/\s*([^,]*)\s*$/)[1]; // get everything after the last "," and trim it
			$source(request, response);
		});
	};
})(jQuery);