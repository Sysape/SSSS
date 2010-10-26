/**
 * jQuery confirmation box plugin
 * @author Michał Bielawski <d3x@burek.it>
 * @name jQuery confirm()
 * @license WTFPL (http://sam.zoy.org/wtfpl/)
 */
(function($) {
	var defaults = {
		question: "Are you sure?",
		yes: "Yes",
		no: "No"
	};
	$.fn.extend({
		confirm: function(question, yes, no) {
			if(typeof(question) == "undefined")
				question = defaults.question;
			if(typeof(yes) == "undefined")
				yes = defaults.yes;
			if(typeof(no) == "undefined")
				no = defaults.no;
			return this.each(function() {
				$(this).click(function(e) {
					e.preventDefault();
					$('body').append(
						$('<div>', {"class" : "jquery-confirmation-overlay"}).
						after($('<div>', {"class": "jquery-confirmation-box"}).append(
							$('<h1>', {text: question}).
							after($('<span>', {"class": "jquery-confirmation-yes"}).append(
								$(this).clone(true).removeAttr("class").text(yes)
							)).
							after($('<span>', {"class": "jquery-confirmation-yes"}).append(
								$('<a>', {click: function() {
									$('.jquery-confirmation-overlay, .jquery-confirmation-box').fadeOut(40, function() {
										$(this).remove();
									});
								}, text: no})
							))
						)).fadeIn(40)
					);
				});
			});
		}
	})
})(jQuery);
