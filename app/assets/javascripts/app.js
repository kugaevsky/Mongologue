(function($){
	$.fn.maxChar = function(limit, options) {


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

		var target = $(this);

		var debug = settings.debug;
		var indicatorId = settings.indicator;
		var label = settings.label;
		var pluralMessage = settings.pluralMessage;
		var rate = settings.rate;
		var singularMessage = settings.singularMessage;
		var spaceBeforeMessage = settings.spaceBeforeMessage;
		var truncate = settings.truncate;

		var currentMessage = '';
		var indicator = getIndicator(indicatorId);
		var limit = limit;
		var remaining = limit;
		var timer = null;

		if(label) {
			indicator.text(label);
		} else {
			update(limit);
		}

		$(this).focus(function(){
			if(timer == null) {
				if(label) {
					indicator.fadeOut(function(){indicator.text('')}).fadeIn(function(){start()});
				} else {
					start();
				}
			}
		});

		$(this).blur(function() {
			stop();
			if(label) {
				indicator.fadeOut(function(){indicator.text(label)}).fadeIn();
			}
		});

		function getIndicator(id){
			var indicator = $('#'+id);
			if(indicator.length == 0) {
				target.after(spaceBeforeMessage + '<span id="'+id+'"></span>');
				indicator = $('#'+id)
			}
			return indicator;
		}

		function log(message) {
			if(debug) {
				try {
					if(console) {
						console.log(message);
					}
				} catch(e) {
				}
			}
		}

		function start() {
			timer = setInterval(function(){update(limit)}, rate);
		}

		function stop() {
			if(timer != null) {
				clearInterval(timer);
				timer = null;
			}
		}

		if(truncate) {
			var form_id = '#' + $(this).closest("form").attr("id");
			$(form_id).submit(function(){
				target.val(target.val().slice(0,limit));
			});
		}

		function update(limit){
			var remaining = limit - target.val().length;
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

// Moved from main page

  var direction=0;
  var history = window.history;
  var loaded = false;

  $(document).ready(function() {

  var tcvisible=$.cookie("tagscloud");
  var atvisible=$.cookie("abouttext");
  var sivisible=$.cookie("siteinfo");
  var tpvisible=$.cookie("topposts");
  var yhvisible=$.cookie("youarehere");


  $('#tagscloud').css("display",tcvisible);
  $('#abouttext').css("display",atvisible);
  $('#siteinfo').css("display",sivisible);
  $('#topposts').css("display",tpvisible);
  $('#youarehere').css("display",yhvisible);


  // $.address.externalChange(function(event) {
  //   if (!loaded) {
  //     loaded = true;
  //     return;
  //   }
  //   $.getScript(event.value);
  // });

  // $.address.internalChange(function(event) {

  // });


  // $.address.init(function(event) {

  // });


  $.ajax({ type: "GET", url: "/tags.txt", success: function(data) {
    var tags = data.split("|");
    var obj = new autosuggest("search",tags);
  }});

  $.getScript('/clientinfo.js');

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
      $.cookie("tagscloud", tcvisible, { expires: 30 } );
      }));
  });

  $("#aboutbutton")
    .click(function() {
    $("#abouttext").toggle({ effect: "blind"},(function(){
      var atvisible=$('#abouttext').css("display");
      $.cookie("abouttext", atvisible, { expires: 30 } );
      }));
  });

  $("#siteinfobutton")
    .click(function() {
    $("#siteinfo").toggle({ effect: "blind"},(function(){
      var sivisible=$('#siteinfo').css("display");
      $.cookie("siteinfo", sivisible, { expires: 30 } );
      }));
  });

  $("#toppostsbutton")
    .click(function() {
    $("#topposts").toggle({ effect: "blind"},(function(){
      var tpvisible=$('#topposts').css("display");
      $.cookie("topposts", tpvisible, { expires: 30 } );
      }));
  });

  $("#youareherebutton")
    .click(function() {
    $("#youarehere").toggle({ effect: "blind"},(function(){
      var yhvisible=$('#youarehere').css("display");
      $.cookie("youarehere", yhvisible, { expires: 30 } );
      }));
  });

 });
