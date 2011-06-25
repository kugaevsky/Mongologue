/* Auto-suggest control
 *
 * (c) 2007-2009 Dmitriy Khudorozhkov (dmitrykhudorozhkov@yahoo.com)
 *
 * Latest version download and documentation:
 * http://www.codeproject.com/KB/scripting/AutoSuggestControl.aspx
 *
 * Based on "Auto-complete Control" by zichun:
 * http://www.codeproject.com/KB/scripting/jsactb.aspx
 *
 * This software is provided "as-is", without any express or implied warranty.
 * In no event will the author be held liable for any damages arising from the
 * use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 *
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software
 *    in a product, an acknowledgment in the product documentation would be
 *    appreciated but is not required.
 *
 * 2. Altered source versions must be plainly marked as such, and must not be
 *    misrepresented as being the original software.
 *
 * 3. This notice may not be removed or altered from any source distribution.
 */

var autosuggest_url = ""; // Global link to the server-side script, that gives you the suggestion list.
			  // Used for controls that do not define their own server script urls.

function autosuggest(id, array, url, onSelect)
{
	// "Public" variables:

	this.time_out      = 0;		// autocomplete timeout, in milliseconds (0: autocomplete never times out)
	this.response_time = 500;	// time, in milliseconds, between the last char typed and the actual query
	this.entry_limit   = 10;	// number of entries autocomplete will show at a time (only if not in scroll mode)

	this.limit_start     = true;	// should the auto complete be limited to the beginning of keyword?
	this.match_first     = true;	// if previous is false, should the exact matches be displayed first?
	this.restrict_typing = false;	// restrict to existing members of array
	this.full_refresh    = false;	// should the script re-send the AJAX request after each typed character?

	this.use_iframe  = true;	// should the control use an IFrame element to fix suggestion list positioning (MS IE only)?
	this.use_scroll  = true;	// should the control use a scroll bar (true) or a up/down arrow-buttons (false)?
	this.use_mouse   = true;	// enable mouse support
	this.no_default  = true;	// should the control omit selecting the 1st item in a suggestion list?
	this.start_check = 0;		// show widget only after this number of characters is typed in (effective if >1)

	this.text_delimiter = [";", ","];	// delimiter for multiple autocomplete entries. Set it to empty array ( [] ) for single autocomplete.
	this.ajax_delimiter = "|"; 			// character that delimits entries in the string returned by AJAX call
	this.item_delimiter = ","; 			// character that delimits key and value for the suggestion item in the string returned by AJAX call

	this.selectedIndex = -1;	// index (zero-based) of the entry last selected

	// Styles:

	this.bg_color    = "#FFFFF0";	// background color for the suggestion list
	this.ar_color    = "#656291";	// background color for the "arrow" rows (used if use_scroll is false)
	this.text_color  = "#000";		// text color for the non-selected suggestions
	this.htext_color = "#F00";		// text color for the selected suggestion
	this.hcolor      = "#D6D7E7";	// background color for the selected suggestion
	this.font        = "Cambria, Georgia, 'Times New Roman',serif";	// font(s) of suggestion items
	this.font_size   = "1.1em";		// font size of suggestion items

	// "Private" variables:

	this.suggest_url = url || (array ? "" : autosuggest_url);	// URL the server-side script that gives you the suggestion list
	this.msie = (document.all && !window.opera);

	this.displayed = false;

	this.delim_words  = [];
	this.current_word = 0;
	this.delim_char   = [];

	this.current    = 0;
	this.total      = 0;
	this.range_up   = 0;
	this.range_down = 0;

	this.previous = 0;
	this.timer    = 0;
	this.rebuild  = false;

	this.bool = [];
	this.rows = [];

	this.onSelect = onSelect || null;

	this.cur_x = 0;
	this.cur_y = 0;
	this.cur_w = 0;
	this.cur_h = 0;

	this.mouse_x = 0;
	this.mouse_y = 0;

	this.mouse_on_list = 0;
	this.caret_moved = false;

	this.field_id = id;
	this.field    = document.getElementById(id);
	this.lastterm = this.field.value;

	this.keywords = [], this.keywords_init = [];
	this.values   = [], this.values_init   = [];

	this.image = ["arrow-down.gif", "arrow-down-d.gif", "arrow-up.gif", "arrow-up-d.gif"];

	return this.construct(array || []);
};

autosuggest.prototype = {

	construct: function(array)
	{
		function callLater(func, obj, param1, param2) { return function() { func.call(obj, param1 || null, param2 || null) }; }

		this.field.autosuggest = this;

		// Precache arrows:

		if(!this.use_scroll)
		{
			for(var i = 0; i < 4; i++)
			{
				var img = new Image;
				img.src = this.image[i];
			}
		}

		// Initialize the control from JS array:

		for(var i = 0, cl = array.length; i < cl; i++)
		{
			var item = array[i];

			if(item.constructor == Array)
			{
				this.keywords[i] = this.keywords_init[i] = item[0];
				this.values[i]   = this.values_init[i]   = item[1];
			}
			else
			{
				this.keywords[i] = this.keywords_init[i] = item;
				this.values[i]   = this.values_init[i]   = "";
			}
		}

		// Create event handlers:

		this.funcClick = this.mouseClick;
		this.funcCheck = this.checkKey;

		this.funcHighlight = this.highlightTable;

		this.funcClear = callLater(this.clearEvents, this);
		this.funcPress = this.keyPress;

		this.funcUp   = callLater(this.scroll, this, true,  1);
		this.funcDown = callLater(this.scroll, this, false, 1);

		this.funcFocus   = callLater(this.focusTable,   this);
		this.funcUnfocus = callLater(this.unfocusTable, this);

		this.addEvent(this.field, "focus", callLater(this.setupEvents, this));

		return this;
	},

	setupEvents: function()
	{
		this.addEvent(document,   "keydown",  this.funcCheck);
		this.addEvent(this.field, "blur",     this.funcClear);
		this.addEvent(document,   "keypress", this.funcPress);
	},

	clearEvents: function()
	{
		// Removes an event handler:
		function removeEvent(obj, event_name, func_ref)
		{
			if(obj.removeEventListener && !window.opera)
			{
				obj.removeEventListener(event_name, func_ref, true);
			}
			else
			{
				obj["on" + event_name] = null;
			}
		}

		var event = window.event;

		if(event && this.cur_h)
		{
			var elem = event.srcElement || event.target;

			var x = this.mouse_x + (document.body.scrollLeft || 0);
			var y = this.mouse_y + (document.body.scrollTop || 0);

			if((elem.id == this.field_id) && (x > this.cur_x && x < (this.cur_x + this.cur_w)) && (y > this.cur_y && y < (this.cur_y + this.cur_h)))
			{
				this.field.focus();
				return;
			}
		}

		removeEvent(document,   "keydown",  this.funcCheck);
		removeEvent(this.field, "blur",     this.funcClear);
		removeEvent(document,   "keypress", this.funcPress);

		this.hide();
	},

	parse: function(n, plen, re)
	{
		if(!n || !n.length)	return "";
		if(!plen) return n;

		var tobuild = [], c = 0, p = n.search(re);

		tobuild[c++] = n.substr(0, p);
		tobuild[c++] = "<u><font face=\"";
		tobuild[c++] = this.font;
		tobuild[c++] = "\">";
		tobuild[c++] = n.substring(p, plen + p);
		tobuild[c++] = "</font></u>";
		tobuild[c++] = n.substring(plen + p, n.length);

		return tobuild.join("");
	},

	build: function()
	{
		if(this.total == 0)
		{
			this.displayed = false;
			return;
		}

		// Offset position from top of the screen
		function curPos(obj, what)
		{
			var coord = 0;
			while(obj)
			{
				coord += obj["offset" + what];
				obj = obj.offsetParent;
			}

			return coord;
		}

		this.rows = [];
		var that = this;

		this.addEvent(document, "mousemove", function(event)
		{
			event = event || window.event;

			that.mouse_x = event.x;
			that.mouse_y = event.y;
		});

		var body = document.getElementById("suggest_table_" + this.field_id);
		if(body)
		{
			this.displayed = false;
			document.body.removeChild(body);

			var helper = document.getElementById("suggest_helper_" + this.field_id);
			if(helper)
				document.body.removeChild(helper);
		}

		var bb = document.createElement("div");
		bb.id  = "suggest_table_" + this.field_id;
		bb.style.position = "absolute";
		bb.style.border = "#000000 solid 1px";
		bb.style.zIndex = 100;

		this.cur_y = curPos(this.field, "Top") + this.field.offsetHeight;
		bb.style.top = this.cur_y + "px";

		this.cur_x = curPos(this.field, "Left");
		bb.style.left = this.cur_x + "px";

		this.cur_w = this.field.offsetWidth - (this.msie ? 2 : 6);
		bb.style.width = this.cur_w + "px";

		this.cur_h = 1;
		bb.style.height = "1px";

		var cc = null;
		if(this.msie && this.use_IFrame)
		{
			var cc = document.createElement("iframe");
			cc.id = "suggest_helper_" + this.field_id;

			cc.src = "javascript:\"<html></html>\";";
			cc.scrolling = "no";
			cc.frameBorder = "no";

			cc.style.display = "block";
			cc.style.position = "absolute";

			cc.style.zIndex = 99;
			cc.style.filter = "progid:DXImageTransform.Microsoft.Alpha(opacity=0)";
		}

		var that = this;
		var showFull = (this.total > this.entry_limit);

		if(this.use_scroll && showFull)
		{
			this.cur_h = Math.ceil(this.entry_limit * parseInt(this.font_size));
			bb.style.height = this.cur_h + "px";

			bb.style.overflow = "auto";
			bb.style.overflowX = "hidden";
		}

		if(cc)
		{
			document.body.appendChild(cc);

			cc.style.top = this.cur_y + "px";
			cc.style.left = this.cur_x + "px";

			cc.style.width = bb.offsetWidth + 2;
		}

		document.body.appendChild(bb);

		var first = true, dispCount = showFull ? this.entry_limit : this.total;
		var str = [], cn = 0;

		str[cn++] = "<table cellspacing=\"1px\" cellpadding=\"2px\" style=\"width:100%;background-color:";
		str[cn++] = this.bg_color;
		str[cn++] = "\" id=\"suggest_table2_";
		str[cn++] = this.field_id;
		str[cn++] = "\">";

		bb.innerHTML = str.join("");
		var table = bb.firstChild;

		if(this.use_mouse)
		{
			table.onmouseout  = this.funcUnfocus;
			table.onmouseover = this.funcFocus;
		}

		var real_height = 0, real_width = 0;

		function createArrowRow(_img)
		{
			var row = table.insertRow(-1), rs = row.style;
			rs.backgroundColor = that.ar_color;

			var cell = row.insertCell(0), cs = cell.style;
			cs.cursor = "default";
			cs.textAlign = "center";

			var img = cell.appendChild(document.createElement("img"));
			img.src = that.image[_img];

			real_height += row.offsetHeight + 1;
			return cell;
		}

		if(!this.use_scroll && showFull)
			createArrowRow(3);

		var kl = this.keywords.length, counter = 0, j = 0;

		// For "parse" call:
		var t, plen;
		if(this.text_delimiter.length > 0)
		{
			var word = this.delim_words[this.current_word];

			   t = this.trim(this.addSlashes(word));
			plen = this.trim(word).length;
		}
		else
		{
			var word = this.field.value;

			   t = this.addSlashes(word);
			plen = word.length;
		}

		var re = new RegExp((this.limit_start ? "^" : "") + t, "i");

		function addSuggestion(index, _first)
		{
			var row = that.rows[j] = table.insertRow(-1);
			row.style.backgroundColor = (_first || (that.previous == index)) ? that.hcolor : that.bg_color;

			var cell = row.insertCell(0), cs = cell.style;
			cs.color = (_first || (that.previous == index)) ? that.htext_color : that.text_color;
			cs.fontFamily = that.font;
			cs.fontSize = that.font_size;
			cs.whiteSpace = "nowrap";

			cell.innerHTML = that.parse(that.keywords[index], plen, re);
			cell.setAttribute("pos", j++);
			cell.autosuggest = that;

			if(that.use_mouse)
			{
				cs.cursor = this.msie ? "hand" : "pointer";
				that.addEvent(cell, "click", that.funcClick);
				cell.onmouseover = that.funcHighlight;
			}

			return [row.offsetWidth, row.offsetHeight];
		}

		for(var i = 0; i < kl; i++)
		{
			if(this.bool[i])
			{
				var dim = addSuggestion(i, (first && !this.no_default && !this.rebuild));
				first = false;

				if(counter <= this.entry_limit)
					real_height += dim[1] + 1;

				if(real_width < dim[0])
					real_width = dim[0];

				if(++counter == this.entry_limit)
				{
					++i;
					break;
				}
			}
		}

		var last = i;

		if(!this.use_scroll && showFull)
		{
			var cell = createArrowRow(0);

			if(this.use_mouse)
			{
				cell.style.cursor = this.msie ? "hand" : "pointer";
				this.addEvent(cell, "click", this.funcDown);
			}
		}

		this.cur_h = real_height + 1;
		bb.style.height = this.cur_h + "px";

		this.cur_w = ((real_width > bb.offsetWidth) ? real_width : bb.offsetWidth) + (this.msie ? -2 : 2);
		bb.style.width  = this.cur_w + "px";

		if(cc)
		{
			cc.style.height = this.cur_h + "px";
			cc.style.width  = this.cur_w + "px";
		}

		this.current    = this.no_default ? -1 : 0;
		this.range_up   = 0;
		this.range_down = j - 1;
		this.displayed  = true;

		if(this.use_scroll)
		{
			setTimeout(function()
			{
				counter = 0;

				for(var i = last; i < kl; i++)
				{
					if(!that.displayed) return;

					if(that.bool[i])
					{
						addSuggestion(i);

						if(++counter == that.entry_limit)
						{
							++i;
							break;
						}
					}
				}

				last = i;

				if(j < that.total) setTimeout(arguments.callee, 25);
			},
			25);
		}
	},

	remake: function()
	{
		this.rows = [];

		var a = document.getElementById("suggest_table2_" + this.field_id);
		var k = 0, first = true;

		function adjustArrow(obj, img, cond, handler)
		{
			var hand = obj.msie ? "hand" : "pointer";

			var r = a.rows[k++];
			r.style.backgroundColor = obj.ar_color;

			var c = r.firstChild;
			c.style.cursor = "default";
			c.style.textAlign = "center";

			c.firstChild.src = obj.image[img];

			if(cond && handler && obj.use_mouse)
			{
				obj.addEvent(c, "click", handler);
				c.style.cursor = hand;
			}
		}

		if(this.total > this.entry_limit)
		{
			var b = (this.range_up > 0);
			adjustArrow(this, b ? 2 : 3, b, this.funcUp);
		}

		// For "parse" call:
		var t, plen;
		if(this.text_delimiter.length > 0)
		{
			var word = this.delim_words[this.current_word];

			   t = this.trim(this.addSlashes(word));
			plen = this.trim(word).length;
		}
		else
		{
			var word = this.field.value;

			   t = this.addSlashes(word);
			plen = word.length;
		}

		var re = new RegExp((this.limit_start ? "^" : "") + t, "i");
		var kl = this.keywords.length, j = 0;

		for(var i = 0; i < kl; i++)
		{
			if(this.bool[i])
			{
				if((j >= this.range_up) && (j <= this.range_down))
				{
					var r = this.rows[j] = a.rows[k++];
					r.style.backgroundColor = this.bg_color;

					var c = r.firstChild;
					c.style.color = this.text_color;
					c.style.fontFamily = this.font;
					c.style.fontSize = this.font_size;
					c.innerHTML = this.parse(this.keywords[i], plen, re);
					c.setAttribute("pos", j);
				}

				if(++j > this.range_down) break;
			}
		}

		if(kl > this.entry_limit)
		{
			var b = (j < this.total);
			adjustArrow(this, b ? 0 : 1, b, this.funcDown);
		}

		if(this.msie)
		{
			var helper = document.getElementById("suggest_helper_" + this.field_id);
			if(helper) helper.style.width = a.parentNode.offsetWidth + 2;
		}
	},

	startTimer: function(on_list)
	{
		if(this.time_out > 0)
			this.timer = setTimeout(function() { this.mouse_on_list = on_list; this.hide(); }, this.time_out);
	},

	stopTimer: function()
	{
		if(this.timer)
		{
			clearTimeout(this.timer);
			this.timer = 0;
		}
	},

	getRow: function(index)
	{
		if(typeof(index) == "undefined") index = this.current;

		return (this.rows[index] || null);
	},

	fixArrows: function(base)
	{
		if(this.total <= this.entry_limit) return;

		var table = base.firstChild, at_start = (this.current == 0), at_end = (this.current == (this.total - 1));
		var hand = (this.msie ? "hand" : "pointer");

		var cell = table.rows[0].firstChild;
		cell.firstChild.src = this.image[at_start ? 3 : 2];
		cell.style.cursor = at_start ? "default" : hand;

		cell = table.rows[this.entry_limit + 1].firstChild;
		cell.firstChild.src = this.image[at_end ? 1 : 0];
		cell.style.cursor = at_end ? "default" : hand;
	},

	scroll: function(direction, times)
	{
		if(!this.displayed) return;

		this.field.focus();
		if(this.current == (direction ? 0 : (this.total - 1))) return;

		if(!direction && (this.current < 0))
		{
			this.current = -1;
		}
		else
		{
			var t = this.getRow();

			if(t && t.style)
			{
				t.style.backgroundColor = this.bg_color;
				t.firstChild.style.color = this.text_color;
			}
		}

		this.current += times * (direction ? -1 : 1);
		if(direction)
		{
			if(this.current < 0)
				this.current = 0;
		}
		else
		{
			if(this.current > (this.total - 1))
				this.current = this.total - 1;
		}

		var t = this.getRow(), base = document.getElementById("suggest_table_" + this.field_id);

		if(this.use_scroll && t)
		{
			if(direction)
			{
				if(t.offsetTop < base.scrollTop)
					base.scrollTop = t.offsetTop;
			}
			else
			{
				if((t.offsetTop + t.offsetHeight) > (base.scrollTop + base.offsetHeight))
				{
					var ndx = this.current - this.entry_limit + 1;
					if(ndx > 0)
						base.scrollTop = this.getRow(ndx).offsetTop;
				}
			}
		}
		else
		{
			if(direction)
			{
				if(this.current < this.range_up)
				{
					this.range_up -= times;
					if(this.range_up < 0) this.range_up = 0;

					this.range_down = this.range_up + this.entry_limit - 1;

					this.remake();
				}
				else this.fixArrows(base);
			}
			else
			{
				if(this.current > this.range_down)
				{
					this.range_down += times;
					if(this.range_down > (this.total - 1)) this.range_down = this.total - 1;

					this.range_up = this.range_down - this.entry_limit + 1;

					this.remake();
				}
				else this.fixArrows(base);
			}

			t = this.getRow();
		}

		if(t && t.style)
		{
			t.style.backgroundColor = this.hcolor;
		    t.firstChild.style.color = this.htext_color;
		}

		this.stopTimer();
		this.startTimer(1);

		this.field.focus();
	},

	mouseClick: function(event)
	{
		event = event || window.event;
		var elem = event.srcElement || event.target;

		if(!elem.id) elem = elem.parentNode;

		var obj = elem.autosuggest;

		if(!obj)
		{
			var tag = elem.tagName.toLowerCase();
			elem = (tag == "tr") ? elem.firstChild : elem.parentNode;

			obj = elem.autosuggest;
		}

		if(!obj || !obj.displayed) return;

		obj.mouse_on_list = 0;
		obj.current = parseInt(elem.getAttribute("pos"), 10);
		obj.choose();
	},

	focusTable: function()
	{
		this.mouse_on_list = 1;
	},

	unfocusTable: function()
	{
		this.mouse_on_list = 0;

		this.stopTimer();
		this.startTimer(0)
	},

	highlightTable: function(event)
	{
		event = event || window.event;
		var elem = event.srcElement || event.target;

		var obj = elem.autosuggest;
		if(!obj) return;

		obj.mouse_on_list = 1;

		var row = obj.getRow();
		if(row && row.style)
		{
			row.style.backgroundColor = obj.bg_color;
			row.firstChild.style.color = obj.text_color;
		}

		obj.current = parseInt(elem.getAttribute("pos"), 10);

		row = obj.getRow();
		if(row && row.style)
		{
			row.style.backgroundColor = obj.hcolor;
			row.firstChild.style.color = obj.htext_color;
		}

		obj.stopTimer();
		obj.startTimer(0);
	},

 	choose: function()
	{
		if(!this.displayed) return;
		if(this.current < 0) return;

		this.displayed = false;

		var kl = this.keywords.length;

		for(var i = 0, c = 0; i < kl; i++)
		{
			if(this.bool[i] && (c++ == this.current))
			{
				break;
			}
		}

		this.selectedIndex = i;
		this.insertWord(this.keywords[i]);

		if(this.onSelect)
			this.onSelect(i, this);
	},

	insertWord: function(a)
	{
		// Sets the caret position to l in the object
		function setCaretPos(obj, l)
		{
			obj.focus();

			if(obj.setSelectionRange)
			{
				obj.setSelectionRange(l, l);
			}
			else if(obj.createTextRange)
			{
				var m = obj.createTextRange();
				m.moveStart("character", l);
				m.collapse();
				m.select();
			}
		}

		if(this.text_delimiter.length > 0)
		{
			var str = "", word = this.delim_words[this.current_word], wl = word.length, l = 0;

			for(var i = 0; i < this.delim_words.length; i++)
			{
				if(this.current_word == i)
				{
					var prespace = "", postspace = "", gotbreak = false;

					for(var j = 0; j < wl; ++j)
					{
						if(word.charAt(j) != " ")
						{
							gotbreak = true;
							break;
						}

						prespace += " ";
					}

					for(j = wl - 1; j >= 0; --j)
					{
						if(word.charAt(j) != " ")
							break;

						postspace += " ";
					}

					str += prespace;
					str += a;
					l = str.length;

					if(gotbreak) str += postspace;
				}
				else
				{
					str += this.delim_words[i];
				}

				if(i != this.delim_words.length - 1)
					str += this.delim_char[i];
			}

			this.field.value = str;
			setCaretPos(this.field, l);
		}
		else
		{
			this.field.value = a;
		}

		this.mouse_on_list = 0;
		this.hide();
	},

	hide: function()
	{
		if(this.mouse_on_list == 0)
		{
			this.displayed = false;

			var base = document.getElementById("suggest_table_" + this.field_id);
			if(base)
			{
				var helper = document.getElementById("suggest_helper_" + this.field_id);
				if(helper)
					document.body.removeChild(helper);

				document.body.removeChild(base);
			}

			this.stopTimer();

			this.cur_x = 0;
			this.cur_y = 0;
			this.cur_w = 0;
			this.cur_h = 0;

			this.rows = [];
		}
	},

	keyPress: function(event)
	{
		// On firefox there is no way to distingish pressing shift-8 (asterix)
		// from pressing 8 during the keyDown event, so we do restrict_typing
		// whilest handling the keyPress event

		event = event || window.event;

		var code = window.event ? event.keyCode : event.charCode;
		var obj = event.srcElement || event.target;

		obj = obj.autosuggest;

		if(obj.restrict_typing && !obj.suggest_url.length && (code >= 32))
		{
			var keyw_len = obj.keywords.length;
			var new_term = obj.field.value + String.fromCharCode(code);
			new_term = new_term.toLowerCase();

			for(var i = 0; i < keyw_len; i++)
				if(obj.keywords[i].toLowerCase().indexOf(new_term) != -1)
					break;

			if(i == keyw_len)
			{
				obj.stopEvent(event);
				return false;
			}
		}

		if(obj.caret_moved) obj.stopEvent(event);
		return !obj.caret_moved;
	},

	checkKey: function(event)
	{
		event = event || window.event;

		var code = event.keyCode;
		var obj = event.srcElement || event.target;

		obj = obj.autosuggest;
		obj.caret_moved = 0;

		var term = "";

		obj.stopTimer();

		switch(code)
		{
			// Up arrow:
			case 38:
				if(obj.current <= 0)
				{
					obj.stopEvent(event);
					obj.hide();
				}
				else
				{
					obj.scroll(true, 1);
					obj.caret_moved = 1;
					obj.stopEvent(event);
				}
				return false;

			// Down arrow:
			case 40:
				if(!obj.displayed)
				{
					obj.timer = setTimeout(function()
					{
						obj.preSuggest(-1);
					},
					25);
				}
				else
				{
					obj.scroll(false, 1);
					obj.caret_moved = 1;
				}
				return false;

			// Page up:
			case 33:
				obj.scroll(true, (obj.use_scroll || (obj.getRow() == obj.rows[obj.range_up])) ? obj.entry_limit : (obj.current - obj.range_up));

				obj.caret_moved = 1;
				break;

			// Page down:
			case 34:
				obj.scroll(false, (obj.use_scroll || (obj.getRow() == obj.rows[obj.range_down])) ? obj.entry_limit : (obj.range_down - obj.current));

				obj.caret_moved = 1;
				break;

			// Home
			case 36:
				obj.scroll(true, obj.total);

				obj.caret_moved = 1;
				break;

			// End
			case 35:
				obj.scroll(false, obj.total);

				obj.caret_moved = 1;
				break;

			// Esc:
			case 27:
				term = obj.field.value;

				obj.mouse_on_list = 0;
				obj.hide();
				break;

			// Enter:
			case 13:
				if(obj.displayed)
				{
					obj.caret_moved = 1;
					obj.choose();
					return false;
				}
				break;

			// Tab:
			case 9:
				if((obj.displayed && (obj.current >= 0)) || obj.timer)
				{
					obj.caret_moved = 1;
					obj.choose();

					setTimeout(function() { obj.field.focus(); }, 25);
					return false;
				}
				break;

			case 16: //shift
				break;

			default:
				obj.caret_moved = 0;
				obj.timer = setTimeout(function()
				{
					obj.preSuggest(code);
				},
				(obj.response_time < 10 ? 10 : obj.response_time));
				break;
		}

		if(term.length) setTimeout(function() { obj.field.value = term; }, 25);
		return true;
	},

	preSuggest: function(kc)
	{
		if(!this.timer)
			return;

		this.stopTimer();

		if(this.displayed && (this.lastterm == this.field.value)) return;
		this.lastterm = this.field.value;

		if(kc == 38 || kc == 40 || kc == 13) return;

		var c = 0;
		if(this.displayed && (this.current >= 0))
		{
			for(var i = 0; i < this.keywords.length; i++)
			{
				if(this.bool[i]) ++c;

				if(c == this.current)
				{
					this.previous = i;
					break;
				}
			}
		}
		else
		{
			this.previous = -1;
		}

		if(!this.field.value.length && (kc != -1))
		{
			this.mouse_on_list = 0;
			this.hide();
		}

		var ot, t;

		if(this.text_delimiter.length > 0)
		{
			var caret_pos = this.getCaretEnd(this.field);

			var delim_split = "";
			for(var i = 0; i < this.text_delimiter.length; i++)
				delim_split += this.text_delimiter[i];

			delim_split = this.addSlashes(delim_split);
			var delim_split_rx = new RegExp("([" + delim_split + "])");
			c = 0;
			this.delim_words = [];
			this.delim_words[0] = "";

			for(var i = 0, j = this.field.value.length; i < this.field.value.length; i++, j--)
			{
				if(this.field.value.substr(i, j).search(delim_split_rx) == 0)
				{
					var ma = this.field.value.substr(i, j).match(delim_split_rx);
					this.delim_char[c++] = ma[1];
					this.delim_words[c] = "";
				}
				else
				{
					this.delim_words[c] += this.field.value.charAt(i);
				}
			}

			var l = 0;
			this.current_word = -1;

			for(i = 0; i < this.delim_words.length; i++)
			{
				if((caret_pos >= l) && (caret_pos <= (l + this.delim_words[i].length)))
					this.current_word = i;

				l += this.delim_words[i].length + 1;
			}

			ot = this.trim(this.delim_words[this.current_word]);
			 t = this.trim(this.addSlashes(this.delim_words[this.current_word]));
		}
		else
		{
			ot = this.field.value;
			 t = this.addSlashes(ot);
		}

		if(ot.length == 0 && (kc != -1))
		{
			this.mouse_on_list = 0;
			this.hide();
		}
		else if((ot.length == 1) || this.full_refresh ||
		       ((ot.length > 1) && !this.keywords.length) ||
		       ((ot.length > 1) && (this.keywords[0].charAt(0).toLowerCase() != ot.charAt(0).toLowerCase())))
		{
			var ot_ = ((ot.length > 1) && !this.full_refresh) ? ot.charAt(0) : ot;

			if(this.suggest_url.length)
			{
				// create xmlhttprequest object:
				var http = null;
				if(typeof XMLHttpRequest != "undefined")
				{
					try
					{
						http = new XMLHttpRequest();
					}
					catch (e) { http = null; }
				}
				else
				{
					try
					{
						http = new ActiveXObject("Msxml2.XMLHTTP") ;
					}
					catch (e)
					{
						try
						{
							http = new ActiveXObject("Microsoft.XMLHTTP") ;
						}
						catch (e) { http = null; }
					}
				}

				if(http)
				{
					// Uncomment for local debugging in Mozilla/Firefox:
					// try { netscape.security.PrivilegeManager.enablePrivilege("UniversalBrowserRead"); } catch (e) { }

					if(http.overrideMimeType)
						http.overrideMimeType("text/xml");

					http.open("GET", this.suggest_url + ot_, true);

					var that = this;
					http.onreadystatechange = function(n)
					{
						if(http.readyState == 4)
						{
							if((http.status == 200) || (http.status == 0))
							{
								var text = http.responseText;

								var index1 = text.indexOf("<listdata>");
								var index2 = (index1 == -1) ? text.length : text.indexOf("</listdata", index1 + 10);

								index1 += (index1 != -1) ? 10 : 1;

								var tmpinfo = text.substring(index1, index2);

								if(tmpinfo)
								{
									that.keywords = tmpinfo.split(that.ajax_delimiter);

									if(that.item_delimiter && that.item_delimiter.length)
									{
										var keyword_number = that.keywords.length;
										for(var i = 0; i < keyword_number; i++)
										{
											var ca = that.keywords[i], comma = ca.indexOf(that.item_delimiter);

											if(comma != -1)
											{
												var ci = ca.split(that.item_delimiter);

												that.keywords[i] = that.keywords_init[i] = ci[0];
												that.values[i]   = that.values_init[i]   = ci[1];
											}
											else
											{
												that.values[i] = that.values_init[i] = "";
											}
										}
									}

									that.suggest(ot_, t);
								}
							}
						}
					}

					http.send(null);
				}
			}
			else this.suggest(ot, t);
		}
		else this.suggest(ot, t);
	},

	suggest: function(ot, t)
	{
		if(ot.length < this.start_check) return;

		var al = this.keywords.length;
		this.total = 0, this.rebuild = false;

		if(!this.field.value.length)
		{
			this.total = al;

			for(var i = 0; i < al; i++)
			{
				this.keywords[i] = this.keywords_init[i];
				this.values[i] = this.values_init[i];
				this.bool[i] = true;
			}
		}
		else
		{
			var re1 = new RegExp(((!this.limit_start && !this.match_first) ? "" : "^") + t, "i");
			var re2 = new RegExp(t, "i");

			var after = (!this.limit_start && this.match_first);

			var matchArray = [], matchVArray = [];
			var afterArray = [], afterVArray = [];
			var otherArray = [], otherVArray = [];

			for(var i = 0; i < al; i++)
			{
				var key = this.keywords[i];
				var value = this.values[i];

				if(re1.test(key))
				{
					++this.total;

					matchArray[matchArray.length] = key;
					matchVArray[matchVArray.length] = value;
				}
				else if(after && re2.test(key))
				{
					++this.total;

					afterArray[afterArray.length] = key;
					afterVArray[afterVArray.length] = value;
				}
				else
				{
					otherArray[otherArray.length] = key;
					otherVArray[otherVArray.length] = value;
				}
			}

			this.keywords = matchArray.concat(afterArray).concat(otherArray);
			this.values = matchVArray.concat(afterVArray).concat(otherVArray);

			for(i = 0; i < al; i++)
				this.bool[i] = (i < this.total);
		}

		if(this.previous != -1)
			this.rebuild = true;

		this.startTimer(0);
		this.build();
	},

	// Utility methods:

	// Setup an event handler for the given event and DOM element
	// event_name refers to the event trigger, without the "on", like click or mouseover
	// func_name refers to the function callback that is invoked when event is triggered
	addEvent: function(obj, event_name, func_ref)
	{
		if(obj.addEventListener && !window.opera)
		{
			obj.addEventListener(event_name, func_ref, true);
		}
		else
		{
			obj["on" + event_name] = func_ref;
		}
	},

	// Stop an event from bubbling up the event DOM
	stopEvent: function(event)
	{
		event = event || window.event;

		if(event)
		{
			if(event.stopPropagation) event.stopPropagation();
			if(event.preventDefault) event.preventDefault();

			if(typeof event.cancelBubble != "undefined")
			{
				event.cancelBubble = true;
				event.returnValue = false;
			}
		}

		return false;
	},

	// Get the end position of the caret in the object. Note that the obj needs to be in focus first.
	getCaretEnd: function(obj)
	{
		if(typeof obj.selectionEnd != "undefined")
		{
			return obj.selectionEnd;
		}
		else if(document.selection && document.selection.createRange)
		{
			var M = document.selection.createRange(), Lp;

			try
			{
				Lp = M.duplicate();
				Lp.moveToElementText(obj);
			}
			catch(e)
			{
				Lp = obj.createTextRange();
			}

			Lp.setEndPoint("EndToEnd", M);
			var rb = Lp.text.length;

			if(rb > obj.value.length)
				return -1;

			return rb;
		}

		return -1;
	},

	// String functions:

	addSlashes: function(str) { return str.replace(/(["\\\.\|\[\]\^\*\+\?\$\(\)])/g, "\\$1"); },

	trim: function(str) { return str.replace(/^\s*(\S*(\s+\S+)*)\s*$/, "$1"); }
};