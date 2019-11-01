
var myUV;
window.addEventListener(
	'uvLoaded', 
	function (e) {
		/*
			Identity the key data elements of the web page:
			★ The "popup  html:div which contains the Universal Viewer div, which pops up and goes away as needed
			★ The Universal Viewer html:div itself (the contents of which are managed by UV)
			* The URI of the IIIF manifest, which describes the manuscript as a collection of images with associated metadata
			★ The thumbnail images which are embedded in the textual transcription at the point where the transcription of that folio starts
		*/
		var uvDiv = document.getElementById('uv');
		var popupDiv = document.getElementById('popup');
		var manifestUri = uvDiv.getAttribute("data-manifest");
		var thumbnails = document.querySelectorAll("div.transcription *.thumbnail");
		/*
			Attach a "click" event listener to each thumbnail image, to update the UV's current canvas to match that thumbnail
		*/
		for (var i=0; i < thumbnails.length; i = i + 1) {
			thumbnails.item(i).setAttribute("data-canvas-index", i);
			thumbnails.item(i).addEventListener(
				"click",
				function(event) {
					// Clicking a thumbnail image should bring up UV with the corresponding canvas in focus 
					// The thumbnail image's "data-canvas-index" attribute contains its position in the sequence of folios, starting from 0, going to n-1
					myUV.set(
						{"canvasIndex": this.getAttribute("data-canvas-index")}
					);
					// Activate the popup window
					popupDiv.className = "popup active"; // replacing "popup inactive"
					// uv-embedding.css is responsible for actually showing the "popup" div when it is "active", and hiding it when it's "inactive"
				}
			);
		}
		/*
			Attach a "click" event listener to the "popup" div, for deactivating the popup and returning to the textual transcription, when
			the user clicks outside of the UV panel.
			The "popup" div covers the entire browser window with a tinted transparent panel, with UV itself as a panel in the middle. 
			Clicking on this tinted portion of the screen should close the popup.
		*/
		popupDiv.addEventListener(
			"click",
			function(e) {
				/*
					The "click" events handled here may have been triggered by the user clicking on the tinted background directly, 
					or they may be events which were produced by the user clicking on part of UV, but which were not dealt with by UV, 
					and consequently fell through to the popup panel beneath. 
					The listener therefore ignores  any clicks which were produced by UV itself, otherwise
					clicking on e.g. a folio image in UV would immediately close the popup.
				*/
				if (e.target == e.currentTarget) // Source of the click event is the popup div itself
					// Deactivate the popup window
					this.className = "popup inactive"; // replacing "popup inactive"
			}
		);
		myUV = createUV(
			'#uv', 
			{
				iiifResourceUri: manifestUri, // the URI of the IIIF manifest for this text
				root: '../../uv', // The base URI for UV's resources. It's effectively "/static/uv", but UV requires that it be specified as a page-relative URI.
				isLightbox: true
			}, 
			new UV.URLDataProvider(false) // true ⇒ don't modify URL fragment id
		);
		myUV.on(
			"created", 
			function(obj) {
				console.log('parsed metadata', myUV.extension.helper.manifest.getMetadata());
				console.log('raw jsonld', myUV.extension.helper.manifest.__jsonld);
				// Links and synchronisation between the folio markers in the transcript and the images of those folios in Universal Viewer
				
				// TODO Add a hash change listener to activate the "uv" container css when the URL contains uv hash parameters
				// When the UV container is closed/hidden, update the page URI to the @id of the current page
				var canvases = myUV.extension.helper.manifest.__jsonld.sequences[0].canvases;
			}
		);
	}, 
	false
);