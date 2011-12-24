var canvas;
var stage;
var bmp;

// anaglyph mode vars
var processcanvas;
var resultcanvas;
var ctx3D;
var ctxbase;

var leftbmp;
var rightbmp;

var processimage;

var leftimgdata;
var rightimgdata;
var leftimgdata_array;
var rightimgdata_array

// interface elements
// squares
var sq1;
var sq2;
// vertical separator
var vert;
// square handles
var hn1;
var hn2;

// element vars
// square positions
var sq1x = 0;
var sq1y = 0;
var sq2x = 0;
var sq2y = 0;

var vertx = 0;
var verty = 0;

// square scaling
var hsize = 300;
var vsize = 360;
var MINSIZE = 200;

// animation preview tick and speed
var now = 0;
var lasttick = 0;
var speed = 8; // 1/10 seconds
var frame = 1;

var HNSIZE = 10;

var VERTWIDTH = 10;
var VERTHEIGHT = 50;

var OFFSET = 0;
var INSET = 10;

var THICK = 2;
var COLOR = "#fff";
var FILL = "#000";
var FILLALPHA = "rgba(0,0,0,0.5)";

var SLOWSPEED = 30;
var MEDSPEED = 15;
var FASTSPEED = 8;

var img = new Image();
var update = true;
var first = true;
var mode = "GIF";
var index = "";

//for ipad
var ua = navigator.userAgent;
var isiPad = /iPad/i.test(ua) || /iPod/i.test(ua) || /iPhone/i.test(ua);
var isdown = false;

function init() {
	//find canvas and load images, wait for last image to load
	canvas = document.getElementById("testCanvas");
	processcanvas = document.getElementById("processCanvas");
	resultcanvas = document.getElementById("resultCanvas");
	
	document.getElementById("btnNext").onclick = generate;
	
	document.getElementById("toggleGIF").onclick = function(){toggleMode("GIF");};
	document.getElementById("toggleAna").onclick = function(){toggleMode("ANAGLYPH");};
	
	document.getElementById("slowSpeed").onclick = function(){changeSpeed(SLOWSPEED);};
	document.getElementById("medSpeed").onclick = function(){changeSpeed(MEDSPEED);};
	document.getElementById("fastSpeed").onclick = function(){changeSpeed(FASTSPEED);};
	
	stage = new Stage(canvas);
	stage.enableMouseOver(10);
	Touch.enable(stage);
	
	changeSpeed(speed);
	toggleMode(mode);

	loadPhoto(index);
	
	Ticker.setInterval(10);
}

function centerPhoto() {
	// center horizontally
	OFFSET = Math.floor((canvas.width - img.width)/2);

	bmp.x = OFFSET;
	bmp.y = 0;
}

function run() {
	// init animation timer
	lasttick = new Date().getTime();

	// place image in bitmap:
	bmp = new Bitmap(img);
	stage.addChild(bmp);
	
	centerPhoto();
	
	// starting points for squares
	sq1x = bmp.x + (img.width / 2) - hsize - INSET;
	sq1y = bmp.y + (img.height / 2) - (vsize / 2);
	sq2x = bmp.x + (img.width / 2) + INSET;
	sq2y = bmp.y + (img.height / 2) - (vsize / 2);
	
	// starting point for vertical bar
	vertx = bmp.x + (img.width / 2);
	verty = bmp.y + (img.height / 2);
	
	// the squares
	sq1 = new Shape();
	sq1.over = false;
	// to control for mouse position when dragging
	sq1.mx = 0;
	sq1.my = 0;
	stage.addChildAt(sq1,1);
	// handle
	hn1 = new Shape();
	hn1.over = false;
	// to control for mouse position when dragging
	hn1.mx = 0;
	hn1.my = 0;
	hn1.sx = 0;
	hn1.sx = 0;
	stage.addChild(hn1);
	
	sq2 = new Shape();
	sq2.over = false;
	// to control for mouse position when dragging
	sq2.mx = 0;
	sq2.my = 0;
	stage.addChildAt(sq2,1);
	// handle
	hn2 = new Shape();
	hn2.over = false;
	// to control for mouse position when dragging
	hn2.mx = 0;
	hn2.my = 0;
	hn2.sx = 0;
	hn2.sy = 0;
	stage.addChild(hn2);
	
	// vertical handle
	vert = new Shape();
	vert.over = false;
	// to control for mouse position when dragging
	vert.mx = 0;
	vert.sq1x = 0;
	vert.sq2x = 0;
	stage.addChild(vert);
	
	// adding interaction
	addBasicInteractivity();
	
	Ticker.addListener(window);
}

function addBasicInteractivity() {
	// handle movement for VERTICAL handle
	// wrapper function to provide scope for the event handlers:
	(function(target) {
		vert.onPress = function(evt) {
			// drag
			vert.mx = vertx - stage.mouseX;
			vert.sq1x = vertx - sq1x;
			vert.sq2x = vertx - sq2x;
			//console.log("vs1:"+vert.sq1x+" vs2:"+vert.sq2x+" s1:"+sq1x+" s2:"+sq2x+" vm:"+vert.mx+" vx:"+vertx);
			evt.onMouseMove = function(ev) {
				vertx = stage.mouseX + target.mx;
				// move squares along with bar
				sq1x = vertx - target.sq1x;
				sq2x = vertx - target.sq2x;
				// indicate that the stage should be updated on the next tick:
				update = true;
			};
			// optimize for iPad
			isdown = true;
			evt.onMouseUp = function (ev) {
				isdown = false;
			}
		};
		vert.onMouseOver = function() {
			target.over = true;
			update = true;
		};
		vert.onMouseOut = function() {
			target.over = false;
			update = true;
		};
	})(vert);

	// handle movement for LEFT square
	// wrapper function to provide scope for the event handlers:
	(function(target) {
		sq1.onPress = function(evt) {
			// drag
			// save mouse position for future reference
			sq1.mx = sq1x - stage.mouseX;
			sq1.my = sq1y - stage.mouseY;
			var d = vertx - sq1x;
			evt.onMouseMove = function(ev) {
				if (stage.mouseX + target.mx + hsize < vertx) {
					sq1x = stage.mouseX + target.mx;
				} else {
					sq1x = vertx - hsize - 1;
				}
				sq1y = stage.mouseY + target.my;
				// move the other square in a mirror direction
				d = vertx - sq1x;
				sq2x = vertx + d - hsize;
				sq2y = sq1y;
				// indicate that the stage should be updated on the next tick:
				update = true;
			};
			// optimize for iPad
			isdown = true;
			evt.onMouseUp = function (ev) {
				isdown = false;
			}
		};
		sq1.onMouseOver = function() {
			target.over = true;
			update = true;
		};
		sq1.onMouseOut = function() {
			target.over = false;
			update = true;
		};
	})(sq1);

	// handle movement for RIGHT square
	// wrapper function to provide scope for the event handlers:
	(function(target) {
		sq2.onPress = function(evt) {
			// drag
			// save mouse position for future reference
			sq2.mx = sq2x - stage.mouseX;
			sq2.my = sq2y - stage.mouseY;
			var d = vertx - sq2x;
			evt.onMouseMove = function(ev) {
				if (stage.mouseX + target.mx > vertx) {
					sq2x = stage.mouseX + target.mx;
				} else {
					sq2x = vertx + 1;
				}
				sq2y = stage.mouseY + target.my;
				// move the other square in a mirror direction
				d = vertx - sq2x;
				sq1x = vertx + d - hsize;
				sq1y = sq2y;
				// indicate that the stage should be updated on the next tick:
				update = true;
			};
			// optimize for iPad
			isdown = true;
			evt.onMouseUp = function (ev) {
				isdown = false;
			}
		};
		sq2.onMouseOver = function() {
			target.over = true;
			update = true;
		};
		sq2.onMouseOut = function() {
			target.over = false;
			update = true;
		};
	})(sq2);

	// handle resizing TOP LEFT
	// wrapper function to provide scope for the event handlers:
	(function(target) {
		hn1.onPress = function(evt) {
			// drag
			// save mouse position for future reference
			hn1.mx = stage.mouseX;
			hn1.my = stage.mouseY;
			hn1.sx = hsize;
			hn1.sy = vsize;
			evt.onMouseMove = function(ev) {
				if (stage.mouseX + MINSIZE < vertx) {
					hsize = target.sx + (hn1.mx - stage.mouseX);
					sq1x = stage.mouseX;
					sq2x = vertx + vertx - sq1x - hsize;
				}
				if (stage.mouseY + MINSIZE < bmp.y + img.height) {
					vsize = target.sy + (hn1.my - stage.mouseY);
					sq1y = stage.mouseY;
					sq2y = sq1y;
				}
				// indicate that the stage should be updated on the next tick:
				update = true;
			};
			// optimize for iPad
			isdown = true;
			evt.onMouseUp = function (ev) {
				isdown = false;
			}
		};
		hn1.onMouseOver = function() {
			target.over = true;
			update = true;
		};
		hn1.onMouseOut = function() {
			target.over = false;
			update = true;
		};
	})(hn1);

	// handle resizing TOP RIGHT
	// wrapper function to provide scope for the event handlers:
	(function(target) {
		hn2.onPress = function(evt) {
			// drag
			// save mouse position for future reference
			hn2.mx = stage.mouseX;
			hn2.my = stage.mouseY;
			hn2.sx = hsize;
			hn2.sy = vsize;
			evt.onMouseMove = function(ev) {
				if (stage.mouseX - MINSIZE > vertx) {
					hsize = stage.mouseX - sq2x;
					sq2x = stage.mouseX - hsize;
					sq1x = vertx + vertx - sq2x - hsize;
				}
				if (stage.mouseY + MINSIZE < bmp.y + img.height) {
					vsize = target.sy + (hn2.my - stage.mouseY);
					sq2y = stage.mouseY;
					sq1y = sq2y;
				}
				// indicate that the stage should be updated on the next tick:
				update = true;
			};
			// optimize for iPad
			isdown = true;
			evt.onMouseUp = function (ev) {
				isdown = false;
			}
		};
		hn2.onMouseOver = function() {
			target.over = true;
			update = true;
		};
		hn2.onMouseOut = function() {
			target.over = false;
			update = true;
		};
	})(hn2);
}

function draw() {
	drawStereoscope();
}

function drawStereoscope() {
	drawVertical();
	drawSquare(sq1, sq1x, sq1y);
	drawSquare(sq2, sq2x, sq2y);
}

function drawVertical() {
	var g = vert.graphics;
	g.clear();
	g.setStrokeStyle(THICK, "round", "round");
	g.beginStroke(COLOR);
	g.beginFill(FILLALPHA);
	g.drawRect(vertx - (VERTWIDTH / 2), verty - (VERTHEIGHT / 2),VERTWIDTH,VERTHEIGHT);
	g.moveTo(vertx, verty - (VERTHEIGHT / 2)).lineTo(vertx, verty - (VERTHEIGHT * 2)).moveTo(vertx, verty + (VERTHEIGHT / 2)).lineTo(vertx, verty);
}

function drawSquare(square,x,y) {
	var g = square.graphics;
	var g2;
	var CROSSSIZE = INSET;
	g.clear();
	g.setStrokeStyle(THICK, "round", "round");
	g.beginStroke(COLOR);
	g.beginFill(FILLALPHA);
	g.drawRect(x,y,hsize,vsize);
	if (square.over) {
		CROSSSIZE = INSET*2;
		g.moveTo(x-CROSSSIZE+hsize/2,y-CROSSSIZE+vsize/2).lineTo(x+CROSSSIZE+hsize/2,y+CROSSSIZE+vsize/2).moveTo(x+CROSSSIZE+hsize/2,y-CROSSSIZE+vsize/2).lineTo(x-CROSSSIZE+hsize/2,y+CROSSSIZE+vsize/2);
	}
	if (square==sq1) {
		// place top left
		g2 = hn1.graphics;
		g2.clear();
		g2.setStrokeStyle(THICK, "round", "round");
		g2.beginStroke(COLOR);
		g2.beginFill(FILL);
		if (hn1.over) {
			// rollover for handle
			g2.beginFill(COLOR);
		}
		g2.drawRect(x-(HNSIZE/2),y-(HNSIZE/2),HNSIZE,HNSIZE);
	} else {
		// place top right
		g2 = hn2.graphics;
		g2.clear();
		g2.setStrokeStyle(THICK, "round", "round");
		g2.beginStroke(COLOR);
		g2.beginFill(FILL);
		if (hn2.over) {
			// rollover for handle
			g2.beginFill(COLOR);
		}
		g2.drawRect(x+hsize-(HNSIZE/2),y-(HNSIZE/2),HNSIZE,HNSIZE);
	}
}

function tick() {
	// this set makes it so the stage only re-renders when an event handler indicates a change has happened.
	if (update) {
		update = false; // only update once
		draw();
		updatePreview();
		stage.update();
	}
	if (mode=="GIF") {
		drawGIF();
	} else {
		drawAnaglyph();
	}
}

function updatePreview() {
	var p = document.getElementById("previewGIF");
	console.log("p:"+p+" w:"+hsize+" h:"+vsize);
	p.style.width = hsize + "px";
	p.style.height = vsize + "px";
	// center the preview
	document.getElementById("previewContainer").style.left = Math.floor((canvas.width - hsize)/2) + "px";
	document.getElementById("preview").style.height = vsize + "px";
}

function toggleMode(m) {
	mode = m;
	var gifDiv = $("#toggleGIF");
	var anaDiv = $("#toggleAna");
	var linksDiv = $("#toggleLinks");
	var extraDiv = $("#GIFExtraLinks");
	if (m=="GIF") {
		linksDiv.removeClass("anaglyphActive"); 
		linksDiv.addClass("GIFActive"); 
		anaDiv.removeClass("active"); 
		gifDiv.addClass("active"); 
		extraDiv.show(); 
	} else {
		linksDiv.addClass("anaglyphActive"); 
		linksDiv.removeClass("GIFActive"); 
		gifDiv.removeClass("active"); 
		anaDiv.addClass("active"); 
		extraDiv.hide(); 
	}
}

function drawGIF () {
	// get rid of anaglyph canvas in preview
	document.getElementById("previewGIF").style.display = "block";
	document.getElementById("previewAnaglyph").style.display = "none";
	
	now = new Date().getTime();
	if (now - lasttick >= speed) {
		lasttick = now;
		var p = document.getElementById("previewGIF");
		if (frame==1) {
			// left
			p.style.backgroundPosition = ((-1*sq1x)+OFFSET) + "px " + ((-1*sq1y)) + "px";
			frame = 2;
		} else {
			// right
			p.style.backgroundPosition = ((-1*sq2x)+OFFSET) + "px " + ((-1*sq2y)) + "px";
			frame = 1;
		}
	}
}

function drawAnaglyph () {
	// get rid of background in preview
	document.getElementById("previewGIF").style.display = "none";
	document.getElementById("previewAnaglyph").style.display = "block";
	now = new Date().getTime();
	// left = 0,255,255
	// right = 255,0,0
	
	// *** RIGHT IMAGE
	// Get the image data
	rightimgdata = ctxbase.getImageData(sq1x-OFFSET, sq1y, hsize, vsize);
	rightimgdata_array = rightimgdata.data;

	// *** LEFT IMAGE
	// Get the image data
	leftimgdata = ctxbase.getImageData(sq2x-OFFSET, sq2y, hsize, vsize);
	leftimgdata_array = leftimgdata.data;

	// if iPad, do a smaller preview (1/4 size)
	resultcanvas.width = hsize;
	resultcanvas.height = vsize;
	
	var i; 
	var j = rightimgdata_array.length;
	var rR, rG, rB;
	for (i = 0; i < j; i+=4) {
		rR = rightimgdata_array[i];
		rG = rightimgdata_array[i+1];
		rB = rightimgdata_array[i+2];
		// right operation
		// Screen blend = 255 - [((255 - Top Color)*(255 - Bottom Color))/255]
		rR = 255;
		rG = 255 - (255 - rightimgdata_array[i+1]);
		rB = 255 - (255 - rightimgdata_array[i+2]);
	
		// Screen blend = 255 - [((255 - Top Color)*(255 - Bottom Color))/255]
		// Multiply blend = (Top Color) * (Bottom Color) /255
		leftimgdata_array[i] = leftimgdata_array[i];
		leftimgdata_array[i+1] = rG;
		leftimgdata_array[i+2] = rB;
	}

	// Write the MULTIPLIED image data to the canvas
	ctx3D.putImageData(leftimgdata, 0, 0);
}

function loadPhoto(str) {
	index = str;
	console.log("photo");
	img.onload = (function () {
		if (first) {
			first = false;
			run();
		}
		centerPhoto();
		update = true;
	});
	// for animated GIF
	var url = "http://images.nypl.org/index.php?id="+index+"&t=w";
	img.src = url;
	var p = document.getElementById("previewGIF");
	p.style.background = "url('"+url+"') no-repeat -10000px -10000px";
	
	// get image data for future processing if anaglyph
	$.getImageData({
		  url: url,
		  success: function(image){
			// Set up the canvas
			ctx3D = resultcanvas.getContext('2d');
			ctxbase = processcanvas.getContext('2d');
			
			// Draw the image on to the BASE canvas
			ctxbase.drawImage(image, 0, 0, image.width, image.height);
		  },
		  error: function(xhr, text_status){
		    // Handle your error here
		    console.log("Could not load image");
		  }
	});

}

function changeSpeed(s) {
	speed = s;
	var sDiv = $("#slowSpeed");
	var mDiv = $("#medSpeed");
	var fDiv = $("#fastSpeed");
	sDiv.removeClass("active");
	mDiv.removeClass("active");
	fDiv.removeClass("active");
	if (s==SLOWSPEED) {
		sDiv.toggleClass("active");
	} else if (s==MEDSPEED) {
		mDiv.toggleClass("active");
	} else {
		fDiv.toggleClass("active");
	}
}

function generate() {
	console.log("generating...");
	document.getElementById("btnNext").disabled = true;
	document.getElementById("btnNext").onclick = {};
	$.ajax({
		url: "/animations/createJson/"+(sq1x-OFFSET)+"/"+(sq1y)+"/"+(sq2x-OFFSET)+"/"+(sq2y)+"/"+hsize+"/"+vsize+"/"+speed+"/"+index+"/"+mode+"/mga.json",
		dataType: 'json',
		data: null,
		success: function(data) {
			if (data.redirect) {
				window.location.href = data.redirect;
			} else {
				console.log("cannot redirect: " + data);
			}
		},
		statusCode: {
		  404: function() {
			alert('Photo not found error (404)');
			document.getElementById("btnNext").disabled = false;
		  },
		  500: function() {
				alert('Internal server error (500)');
				document.getElementById("btnNext").disabled = false;
		  }
		}
	});
}
