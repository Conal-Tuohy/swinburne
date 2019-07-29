/*
Attach a "toggle" listener to each popup menu, to close the other menus
*/
var popupMenus = document.querySelectorAll("nav#main-nav ul li details");

for (var i=0; i < popupMenus.length; i = i + 1) {
	popupMenus.item(i).addEventListener(
		"toggle",
		function(event) {
			if (this.open) {
				for (var i=0; i < popupMenus.length; i = i + 1) {
					var menu = popupMenus.item(i);
					if (menu !== this) {
						menu.removeAttribute("open");
					}
				}
			}
		}
	);
}

/* mousing over a details summary should open the detail */
var popupMenuSummaries = document.querySelectorAll("nav#main-nav ul li details");
for (var i=0; i < popupMenuSummaries.length; i = i + 1) {
	popupMenuSummaries.item(i).addEventListener(
		"mouseover",
		function(event) {
			this.setAttribute("open", "open");
			event.stopPropagation();
		}
	);
}

/* mousing over any other part of the page should close the menus */
var body = document.querySelector("body");
body.addEventListener(
	"mouseover",
	function(event) {
		for (var i=0; i < popupMenus.length; i = i + 1) {
			var menu = popupMenus.item(i);
			menu.removeAttribute("open");
		}
	}
);

