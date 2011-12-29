var canvas;
var stage;
var bmp;

var stageWidth = 960;
var stageHeight = 450;

var NUM_ELEMENTS_TO_DOWNLOAD = 2;
var numImagesLoaded = 0;

var resize_sprite;
var vert_sprite;
var corner_sprite;
var sheetpng;
var sheetsrc;

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
var MINSIZE = 50;

var SLOWSPEED = 200;
var MEDSPEED = 140;
var FASTSPEED = 80;

// corner values
var CORNER_POSITION = 0;
var CORNER_TOP_LEFT = 1;
var CORNER_TOP_RIGHT = 2;
var CORNER_BOTTOM_LEFT = 3;
var CORNER_BOTTOM_RIGHT = 4;
var CORNER_OFFSET = 10

// animation preview tick and speed
var now = 0;
var lasttick = 0;
var speed = FASTSPEED;
var frame = 1;

var OFFSET = 0;
var INSET = 10;

var THICK = 2;
var COLOR = "#fff";
var OVERCOLOR = "#f00";
var FILL = "#000";
var FILLALPHA = "rgba(0,0,0,0.5)";

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
	
	canvas.ontouchend = function(){isdown = false;sq1.over=sq2.over=hn1.over=hn2.over=false;};
	
	sheetpng = new Image();
	sheetpng.onload = handleImageLoad;
	sheetpng.onerror = handleImageError;
	
	stage = new Stage(canvas);
	stage.enableMouseOver(10);
	Touch.enable(stage);
	
	changeSpeed(speed);
	toggleMode(mode);

	sheetpng.src = sheetsrc;
	loadPhoto(index);
	
	Ticker.setInterval(10);
}

function prepareSheet() {
	var data = {
		images:[sheetpng],
		frames:[
		        [0,0,18,390,0,9,195],
		        [19,0,18,390,0,9,195],
		        [38,0,14,14,0,7,7],
		        [38,15,14,14,0,7,7]
		        //[x,y,w,h,0,rx,ry],
		    ],
		animations: {
			corner:2,
			cornerover:3,
			vertical:0,
			verticalover:1
		}
	};
	vert_sprite = new BitmapAnimation(new SpriteSheet(data));
	vert_sprite.gotoAndStop("vertical");
	vert_sprite.x = vertx;
	vert_sprite.y = verty;
	corner_sprite = new BitmapAnimation(new SpriteSheet(data));
	corner_sprite.gotoAndStop("corner");
	corner_sprite.mysquare = undefined;
	stage.addChild(vert_sprite);
	stage.addChild(corner_sprite);
	console.log("prepared sprite");
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
	sq1x = bmp.x + Math.round(img.width / 2) - hsize - INSET;
	sq1y = bmp.y + Math.round(img.height / 2) - (vsize / 2);
	sq2x = bmp.x + Math.round(img.width / 2) + INSET;
	sq2y = bmp.y + Math.round(img.height / 2) - (vsize / 2);
	
	// starting point for vertical bar
	vertx = bmp.x + (img.width / 2);
	verty = bmp.y + (img.height / 2);
	
	// the squares
	sq1 = new Shape();
	sq1.over = false;
	// to control for mouse position when dragging
	sq1.mx = 0;
	sq1.my = 0;
	stage.addChild(sq1);
	
	sq2 = new Shape();
	sq2.over = false;
	// to control for mouse position when dragging
	sq2.mx = 0;
	sq2.my = 0;
	stage.addChild(sq2);
	
	Ticker.addListener(window);
}

function addBasicInteractivity() {
	// handle movement for VERTICAL handle
	// wrapper function to provide scope for the event handlers:
	(function(target) {
		vert_sprite.onPress = function(evt) {
			// drag
			vert_sprite.mx = vertx - stage.mouseX;
			vert_sprite.sq1x = vertx - sq1x;
			vert_sprite.sq2x = vertx - sq2x;
			//console.log("vs1:"+vert.sq1x+" vs2:"+vert.sq2x+" s1:"+sq1x+" s2:"+sq2x+" vm:"+vert.mx+" vx:"+vertx);
			evt.onMouseMove = function(ev) {
				vertx = stage.mouseX + target.mx;
				// move squares along with bar
				sq1x = vertx - target.sq1x;
				sq2x = vertx - target.sq2x;
				// indicate that the stage should be updated on the next tick:
				update = true;
			};
		};
		vert_sprite.onMouseOver = function() {
			target.over = true;
			update = true;
		};
		vert_sprite.onMouseOut = function() {
			target.over = false;
			update = true;
		};
	})(vert_sprite);
	
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
			corner_sprite.mysquare = target;
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
			corner_sprite.mysquare = target;
			update = true;
		};
		sq2.onMouseOut = function() {
			target.over = false;
			update = true;
		};
	})(sq2);

	// handle RESIZING
	// wrapper function to provide scope for the event handlers:
	(function(target) {
		corner_sprite.onPress = function(evt) {
			// drag
			// save mouse position for future reference
			corner_sprite.mx = stage.mouseX - target.x;
			corner_sprite.my = stage.mouseY - target.y;
			corner_sprite.sh = hsize;
			corner_sprite.sv = vsize;
			corner_sprite.x1 = (corner_sprite.mysquare==sq1) ? sq1x : sq2x;
			corner_sprite.y1 = (corner_sprite.mysquare==sq1) ? sq1y : sq2y;
			corner_sprite.x2 = corner_sprite.x1 + hsize;
			corner_sprite.y2 = corner_sprite.y1 + vsize;
			corner_sprite.mode = (corner_sprite.mysquare==sq1) ? "left" : "right";
			evt.onMouseMove = function(ev) {
				if (CORNER_POSITION==CORNER_TOP_LEFT) {
					target.x = stage.mouseX - target.mx;
					if (target.mode=="right" && target.x-CORNER_OFFSET < vertx) {
						// prevent from moving to left side
						target.x = vertx + CORNER_OFFSET + 1;
					}
					if (target.x > target.x2-MINSIZE) {
						target.x = target.x2-MINSIZE;
					}
					hsize = target.x2 - (target.x - CORNER_OFFSET);
					if (hsize < MINSIZE) {
						hsize = MINSIZE;
					}
					target.y = stage.mouseY - target.my;
					if (target.y > target.y2-MINSIZE) {
						target.y = target.y2-MINSIZE;
					}
					vsize = target.y2 - (target.y - CORNER_OFFSET);
					if (vsize < MINSIZE) {
						vsize = MINSIZE;
					}
					if (target.mode=="left") {
						sq1x = target.x - CORNER_OFFSET;
						sq2x = vertx + vertx - sq1x - hsize;
					} else {
						sq2x = target.x - CORNER_OFFSET;
						sq1x = vertx - (sq2x - vertx) - hsize;
					}
					// .y is common to both
					sq1y = target.y - CORNER_OFFSET;
					sq2y = sq1y;
				} else if (CORNER_POSITION==CORNER_TOP_RIGHT) {
					target.x = stage.mouseX - target.mx;
					if (target.mode=="left" && target.x+CORNER_OFFSET > vertx) {
						// prevent from moving to right side
						target.x = vertx - CORNER_OFFSET - 1;
					}
					if (target.x < target.x1+MINSIZE) {
						target.x = target.x1+MINSIZE;
					}
					hsize = (target.x + CORNER_OFFSET) - target.x1;
					if (hsize < MINSIZE) {
						hsize = MINSIZE;
					}
					target.y = stage.mouseY - target.my;
					if (target.y > target.y2-MINSIZE) {
						target.y = target.y2-MINSIZE;
					}
					vsize = target.y2 - (target.y - CORNER_OFFSET);
					if (vsize < MINSIZE) {
						vsize = MINSIZE;
					}
					if (target.mode=="left") {
						sq1x = (target.x + CORNER_OFFSET) - hsize;
						sq2x = vertx + vertx - sq1x - hsize;
					} else {
						sq2x = (target.x + CORNER_OFFSET) - hsize;
						sq1x = vertx - (sq2x - vertx) - hsize;
					}
					// .y is common to both
					sq1y = target.y - CORNER_OFFSET;
					sq2y = sq1y;
				} else if (CORNER_POSITION==CORNER_BOTTOM_LEFT) {
					target.x = stage.mouseX - target.mx;
					if (target.mode=="right" && target.x-CORNER_OFFSET <= vertx) {
						// prevent from moving to left side
						target.x = vertx + CORNER_OFFSET + 1;
					}
					if (target.x > target.x2-MINSIZE) {
						target.x = target.x2-MINSIZE;
					}
					hsize = target.x2 - (target.x - CORNER_OFFSET);
					if (hsize < MINSIZE) {
						hsize = MINSIZE;
					}
					target.y = stage.mouseY - target.my;
					if (target.y < target.y1+MINSIZE) {
						target.y = target.y1+MINSIZE;
					}
					vsize = (target.y + CORNER_OFFSET) - target.y1;
					if (vsize < MINSIZE) {
						vsize = MINSIZE;
					}
					if (target.mode=="left") {
						sq1x = target.x - CORNER_OFFSET;
						sq2x = vertx + vertx - sq1x - hsize;
					} else {
						sq2x = target.x - CORNER_OFFSET;
						sq1x = vertx - (sq2x - vertx) - hsize;
					}
					// .y is common to both
					sq1y = target.y + CORNER_OFFSET - vsize;
					sq2y = sq1y;
				} else if (CORNER_POSITION==CORNER_BOTTOM_RIGHT) {
					target.x = stage.mouseX - target.mx;
					if (target.mode=="left" && target.x+CORNER_OFFSET > vertx) {
						// prevent from moving to right side
						target.x = vertx - CORNER_OFFSET - 1;
					}
					if (target.x < target.x1+MINSIZE) {
						target.x = target.x1+MINSIZE;
					}
					hsize = (target.x + CORNER_OFFSET) - target.x1;
					if (hsize < MINSIZE) {
						hsize = MINSIZE;
					}
					target.y = stage.mouseY - target.my;
					if (target.y < target.y1+MINSIZE) {
						target.y = target.y1+MINSIZE;
					}
					vsize = (target.y + CORNER_OFFSET) - target.y1;
					if (vsize < MINSIZE) {
						vsize = MINSIZE;
					}
					if (target.mode=="left") {
						sq1x = (target.x + CORNER_OFFSET) - hsize;
						sq2x = vertx + vertx - sq1x - hsize;
					} else {
						sq2x = (target.x + CORNER_OFFSET) - hsize;
						sq1x = vertx - (sq2x - vertx) - hsize;
					}
					// .y is common to both
					sq1y = target.y + CORNER_OFFSET - vsize;
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
		corner_sprite.onMouseOver = function() {
			target.over = true;
			update = true;
		};
		corner_sprite.onMouseOut = function() {
			target.over = false;
			update = true;
		};
	})(corner_sprite);
}

function draw() {
	drawStereoscope();
}

function drawStereoscope() {
	drawVertical();
	drawSquare(sq1, sq1x, sq1y);
	drawSquare(sq2, sq2x, sq2y);
	drawCorner();
}

function drawVertical() {
	vert_sprite.x = vertx;
	if (vert_sprite.over) {
		vert_sprite.gotoAndStop("verticalover");
	} else {
		vert_sprite.gotoAndStop("vertical");
	}
}

function drawCorner() {
	var x = -1000
	var y = -1000;
	if (corner_sprite.over) {
		corner_sprite.gotoAndStop("cornerover");
	} else {
		corner_sprite.gotoAndStop("corner");
	}
	if (corner_sprite.mysquare==sq1) {
		x = sq1x;
		y = sq1y;
	} else if (corner_sprite.mysquare==sq2) {
		x = sq2x;
		y = sq2y;
	}
	if (stage.mouseX < x + (hsize/2) && stage.mouseY < y + (vsize/2)) {
		// top left
		CORNER_POSITION = CORNER_TOP_LEFT;
		corner_sprite.x = x+CORNER_OFFSET;
		corner_sprite.y = y+CORNER_OFFSET;
	} else if (stage.mouseX > x + (hsize/2) && stage.mouseY < y + (vsize/2)) {
		// top right
		CORNER_POSITION = CORNER_TOP_RIGHT;
		corner_sprite.x = x+hsize-CORNER_OFFSET;
		corner_sprite.y = y+CORNER_OFFSET;
	} else if (stage.mouseX < x + (hsize/2) && stage.mouseY > y + (vsize/2)) {
		// bottom left
		CORNER_POSITION = CORNER_BOTTOM_LEFT;
		corner_sprite.x = x+CORNER_OFFSET;
		corner_sprite.y = y+vsize-CORNER_OFFSET;
	} else if (stage.mouseX > x + (hsize/2) && stage.mouseY > y + (vsize/2)) {
		// bottom right
		CORNER_POSITION = CORNER_BOTTOM_RIGHT;
		corner_sprite.x = x+hsize-CORNER_OFFSET;
		corner_sprite.y = y+vsize-CORNER_OFFSET;
	}
}

function drawSquare(square,x,y) {
	var g = square.graphics;
	var CROSSSIZE = INSET;
	g.clear();
	g.setStrokeStyle(THICK, "round", "round");
	if (square.over) {
		g.beginStroke(OVERCOLOR);
	} else {
		g.beginStroke(COLOR);
	}
	g.beginFill(FILLALPHA);
	g.drawRect(x,y,hsize,vsize);
	if (square.over) {
		CROSSSIZE = INSET*2;
		g.moveTo(x-CROSSSIZE+hsize/2,y-CROSSSIZE+vsize/2).lineTo(x+CROSSSIZE+hsize/2,y+CROSSSIZE+vsize/2).moveTo(x+CROSSSIZE+hsize/2,y-CROSSSIZE+vsize/2).lineTo(x-CROSSSIZE+hsize/2,y+CROSSSIZE+vsize/2);
	}
}

function tick() {
	// this set makes it so the stage only re-renders when an event handler indicates a change has happened.
	draw();
	if (update) {
		update = false; // only update once
		updatePreview();
	}
	stage.update();
	if (mode=="GIF") {
		drawGIF();
	} else {
		drawAnaglyph();
	}
}

function updatePreview() {
	var p = document.getElementById("previewGIF");
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
	img.onload = handleImageLoad;
	img.onerror = handleImageError;
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
	console.log(speed);
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

function handleImageLoad(e) {
    numImagesLoaded++;

    // If all elements have been downloaded
    if (numImagesLoaded == 2) {
        numImagesLoaded = 0;
		if (first) {
			first = false;
		}
		run();
		prepareSheet();
		// adding interaction
		addBasicInteractivity();
		update = true;
    }
}

//called if there is an error loading the image (usually due to a 404)
function handleImageError(e) {
    console.log("Error Loading Image : " + e.target.src);
}