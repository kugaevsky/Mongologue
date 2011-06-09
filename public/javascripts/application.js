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

////////////////////////////////////////////////////
// Moved from main page
////////////////////////////////////////////////////

  var direction=0;
  var history = window.history;
  var loaded = false;

  $(document).ready(function() {

  var tcvisible=$.cookie("tagscloud");
  var atvisible=$.cookie("abouttext");
  var sivisible=$.cookie("siteinfo");

  $('#tagscloud').css("display",tcvisible);
  $('#abouttext').css("display",atvisible);
  $('#siteinfo').css("display",sivisible);

  $.address.externalChange(function(event) {
    if (!loaded) {
      loaded = true;
      return;
    }
    $.getScript(event.value);
  });

  $.address.internalChange(function(event) {

  });


  $.address.init(function(event) {

  });


  $.ajax({ type: "GET", url: "/tags.txt", success: function(data) {
    var tags = data.split("|");
    var obj = new autosuggest("search",tags);
  }});

  // var obj = new autosuggest("search","","/tags.xml?term=");

  $.fn.disableSelection = function() {
      $(this).attr('unselectable', 'on')
             .css('-moz-user-select', 'none')
             .each(function() {
                 this.onselectstart = function() { return false; };
              });
  };

  $(".button").disableSelection();

  $("#tagsbutton")
    .click(function() {
    $("#tagscloud").toggle({ effect: "blind"},(function(){
      var tcvisible=$('#tagscloud').css("display");
      $.cookie("tagscloud", tcvisible);
      }));
  });

  $("#aboutbutton")
    .click(function() {
    $("#abouttext").toggle({ effect: "blind"},(function(){
      var atvisible=$('#abouttext').css("display");
      $.cookie("abouttext", atvisible);
      }));
  });

  $("#siteinfobutton")
    .click(function() {
    $("#siteinfo").toggle({ effect: "blind"},(function(){
      var sivisible=$('#siteinfo').css("display");
      $.cookie("siteinfo", sivisible);
      }));
  });


 });
