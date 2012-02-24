var image_array = [];

var canvas;
var stage;
var bmp;

var stageWidth = 800;
var stageHeight = 550;

var numImagesLoaded = 0;

var resize_sprite;
var vert_sprite;
var corner_sprites;
var sheetpng;
var sheetsrc;

// anaglyph mode vars
var processcanvas;
var resultcanvas;
var ctx3D;
var ctxbase;

var processimage;

var leftimgdata;
var rightimgdata;
var leftimgdata_array;
var rightimgdata_array

// interface elements

// background
var bg;

// squares
var sq1;
var sq2;

// text
var txt;
var vtxt;

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
var MINSIZE = 80;
var MAXW = 399;
var MAXH = 490;

var SLOWSPEED = 200;
var MEDSPEED = 140;
var FASTSPEED = 80;

// corner values
var CORNER_POSITION = 0;
var CORNER_TOP_LEFT = 1;
var CORNER_TOP_RIGHT = 2;
var CORNER_BOTTOM_LEFT = 3;
var CORNER_BOTTOM_RIGHT = 4;
var CORNER_OFFSET = 10;

// vertical bar values
var VERTWIDTH = 10;
var VERTHEIGHT = 60;

// animation preview tick and speed
var now = 0;
var lasttick = 0;
var speed = FASTSPEED;
var frame = 1;

var OFFSET = 0;// distance from edge to bmp
var INSET = 10;// initial distance from vert to squares

var THICK = 2;
var COLOR = "#ffffff";
var OVERCOLOR = "#f00";
var FILL = "#000";
var FILLALPHA = "rgba(0,0,0,0.1)";
var BACKALPHA = "rgba(0,0,0,0.75)";

var img = new Image();
var update = true;
var previewActive = false;
var mode = "GIF";
var index = "";

//for ipad
var ua = navigator.userAgent;
var isiPad = /iPad/i.test(ua) || /iPod/i.test(ua) || /iPhone/i.test(ua);
var isdown = false;

var helpVisible = false;

//////// ROTATION STUFF

var rotateLeftBtn;
var rotateRightBtn;
var rotateSize = 30;
var imageRotation = 0;
var maxRotation = 3; // no image is skewed more than these degrees
var rotationIncrement = .1;
var rotateText;
var modeText;
var modeBtn;
var drawMode = "normal";
var grid;
var imagesLoaded = 0;

function init() {
	$("#yescanvas").show();
	$("#nocanvas").hide();
	toggleInstructions();
	//find canvas and load images, wait for last image to load
	canvas = document.getElementById("testCanvas");
	processcanvas = document.getElementById("processCanvas");
	resultcanvas = document.getElementById("resultCanvas");
	
	document.getElementById("btnNext").onclick = generate;
	
	$("#btnNext").hide();
	
	document.getElementById("toggleGIF").onclick = function(){toggleMode("GIF");};
	document.getElementById("toggleAna").onclick = function(){toggleMode("ANAGLYPH");};
	
	document.getElementById("slowSpeed").onclick = function(){changeSpeed(SLOWSPEED);};
	document.getElementById("medSpeed").onclick = function(){changeSpeed(MEDSPEED);};
	document.getElementById("fastSpeed").onclick = function(){changeSpeed(FASTSPEED);};
	
	canvas.ontouchend = function(){isdown = false;sq1.over=sq2.over=vert_sprite.over=false;};
	canvas.ontouchstart = function(){previewActive=true;};
	
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

function centerPhoto() {
	// center horizontally
	OFFSET = Math.floor((canvas.width - img.width)*.5);

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
	
	// background black
	bg = new Shape();
	stage.addChild(bg);
	
	// starting points for squares
	sq1x = bmp.x + Math.round(img.width * .5) - hsize - INSET;
	sq1y = bmp.y + Math.round(img.height * .5) - (vsize * .5);
	sq2x = bmp.x + Math.round(img.width * .5) + INSET;
	sq2y = bmp.y + Math.round(img.height * .5) - (vsize * .5);
	
	// starting point for vertical bar
	vertx = bmp.x + (img.width * .5);
	verty = bmp.y + (img.height * .5);
	
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
	
	// draw square help text
	txt = new Text("drag me", "20px share-regular,'Arial Narrow',sans-serif", "#fff");
	txt.textBaseline = "middle";
	txt.lineWidth = 80;
	txt.x = 0;
	txt.y = -100;
	stage.addChild(txt);
	
	// draw vertical help text
	vtxt = new Text("<- shift axis   shift axis ->", "20px share-regular,'Arial Narrow',sans-serif", "#fff");
	vtxt.textBaseline = "middle";
	vtxt.lineWidth = 216;
	vtxt.x = -1000;
	vtxt.y = 445;
	stage.addChild(vtxt);

	vert_sprite = new Shape();
	vert_sprite.over = false;
	vert_sprite.x = vertx;
	vert_sprite.y = verty;
	stage.addChild(vert_sprite);
	
	// eight corners
	var i, crnr;
	corner_sprites = [];
	for (i=0;i<8;++i) {
		crnr = new Shape();
		crnr.mysquare = (i<4) ? sq1 : sq2;
		crnr.mode = (i<4) ? "left" : "right";
		// multiplier for corner position
		if (i%4==0) {
			crnr.xfactor = 0;
			crnr.yfactor = 0;
		} else if (i%4==1) {
			crnr.xfactor = 1;
			crnr.yfactor = 0;
		} else if (i%4==2) {
			crnr.xfactor = 0;
			crnr.yfactor = 1;
		} else if (i%4==3) {
			crnr.xfactor = 1;
			crnr.yfactor = 1;
		}
		stage.addChild(crnr);
		corner_sprites[i] = crnr;
	}
	
	grid = new Shape();
	stage.addChild(grid);
	
	rotateLeftBtn = new Shape();
	rotateLeftBtn.over = false;
	rotateLeftBtn.x = 10;
	rotateLeftBtn.y = stageHeight - 20 - rotateSize;
	stage.addChild(rotateLeftBtn);
	
	rotateRightBtn = new Shape();
	rotateRightBtn.over = false;
	rotateRightBtn.x = 15 + rotateSize;
	rotateRightBtn.y = stageHeight - 20 - rotateSize;
	stage.addChild(rotateRightBtn);

	rotateText = new Text("rotate image left/right", "20px share-regular,'Arial Narrow',sans-serif", "#fff");
	rotateText.textBaseline = "middle";
	rotateText.lineWidth = 216;
	rotateText.x = 10 + rotateSize + rotateSize + 10;
	rotateText.y = stageHeight - 20 - (rotateSize*.5);
	stage.addChild(rotateText);

	modeText = new Text("", "20px share-regular,'Arial Narrow',sans-serif", "#fff");
	modeText.textBaseline = "middle";
	modeText.lineWidth = 100;
	modeText.x = 10;
	modeText.y = stageHeight - 20 - (rotateSize*.5);
	stage.addChild(modeText);

	modeBtn = new Shape();
	modeBtn.over = false;
	modeBtn.x = 10;
	modeBtn.y = stageHeight - 20 - rotateSize;
	stage.addChild(modeBtn);

	Ticker.addListener(window);
}

function addInteractivity() {
	// handle interaction for ROTATE MODE button
	// wrapper function to provide scope for the event handlers:
	(function(target) {
		modeBtn.onPress = function(evt) {
			update = true;
			if (drawMode=="normal") {
				drawMode = "rotate";
			} else {
				drawMode = "normal";
				// reload image from server
				getImageFromServer();
			}
		};
		modeBtn.onMouseOver = function() {
			modeText.color = "#f00";
			target.over = true;
			update = true;
		};
		modeBtn.onMouseOut = function() {
			modeText.color = "#fff";
			target.over = false;
			update = true;
		};
	})(modeBtn);
	
	// handle interaction for ROTATE LEFT button
	// wrapper function to provide scope for the event handlers:
	(function(target) {
		rotateLeftBtn.onPress = function(evt) {
			if (imageRotation>-(maxRotation)) {
				imageRotation -= rotationIncrement;
				rotateImage();
				previewActive = true;
				update = true;
			}
		};
		rotateLeftBtn.onMouseOver = function() {
			target.over = true;
			update = true;
		};
		rotateLeftBtn.onMouseOut = function() {
			target.over = false;
			update = true;
		};
	})(rotateLeftBtn);
	
	// handle interaction for ROTATE RIGHT button
	// wrapper function to provide scope for the event handlers:
	(function(target) {
		rotateRightBtn.onPress = function(evt) {
			if (imageRotation<maxRotation) {
				imageRotation += rotationIncrement;
				rotateImage();
				previewActive = true;
				update = true;
			}
		};
		rotateRightBtn.onMouseOver = function() {
			target.over = true;
			update = true;
		};
		rotateRightBtn.onMouseOut = function() {
			target.over = false;
			update = true;
		};
	})(rotateRightBtn);
	
	// handle movement for VERTICAL handle
	// wrapper function to provide scope for the event handlers:
	(function(target) {
		vert_sprite.onPress = function(evt) {
			if (!previewActive) {
				previewActive = true;
				update = true;
			}
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
			if (!previewActive) {
				previewActive = true;
				update = true;
			}

			// drag
			// save mouse position for future reference
			sq1.mx = sq1x - stage.mouseX;
			sq1.my = sq1y - stage.mouseY;
			var d = vertx - sq1x;
			evt.onMouseMove = function(ev) {
				sq1x = stage.mouseX + target.mx;
				if (stage.mouseX + target.mx + hsize > vertx) {
					sq1x = vertx - hsize;
				}
				if (sq1x < 0) {
					sq1x = 0;
				}
				sq1y = stage.mouseY + target.my;
				if (sq1y < 0) {
					sq1y = 0;
				}
				if (sq1y + vsize > stageHeight) {
					sq1y = stageHeight - vsize;
				}
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
			if (!previewActive) {
				previewActive = true;
				update = true;
			}

			// drag
			// save mouse position for future reference
			sq2.mx = sq2x - stage.mouseX;
			sq2.my = sq2y - stage.mouseY;
			var d = vertx - sq2x;
			evt.onMouseMove = function(ev) {
				sq2x = stage.mouseX + target.mx;
				if (stage.mouseX + target.mx < vertx) {
					sq2x = vertx;
				}
				if (sq2x + hsize > stageWidth) {
					sq2x = stageWidth - hsize;
				}
				sq2y = stage.mouseY + target.my;
				if (sq2y < 0) {
					sq2y = 0;
				}
				if (sq2y + vsize > stageHeight) {
					sq2y = stageHeight - vsize;
				}
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

	// handle RESIZING
	// wrapper function to provide scope for the event handlers:
	(function(target) {
		target.onPress = function(evt) {
			if (!previewActive) {
				previewActive = true;
				update = true;
			}

			// drag
			// save mouse position for future reference
			target.mx = stage.mouseX - target.x;
			target.my = stage.mouseY - target.y;
			target.sh = hsize;
			target.sv = vsize;
			target.x1 = (target.mysquare==sq1) ? sq1x : sq2x;
			target.y1 = (target.mysquare==sq1) ? sq1y : sq2y;
			target.x2 = target.x1 + hsize;
			target.y2 = target.y1 + vsize;
			evt.onMouseMove = function(ev) {
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
				// indicate that the stage should be updated on the next tick:
				update = true;
			};
			// optimize for iPad
			isdown = true;
			evt.onMouseUp = function (ev) {
				isdown = false;
			}
		};
		target.onMouseOver = function() {
			target.over = true;
			update = true;
		};
		target.onMouseOut = function() {
			target.over = false;
			update = true;
		};
	})(corner_sprites[0]);
	(function(target) {
		target.onPress = function(evt) {
			if (!previewActive) {
				previewActive = true;
				update = true;
			}

			// drag
			// save mouse position for future reference
			target.mx = stage.mouseX - target.x;
			target.my = stage.mouseY - target.y;
			target.sh = hsize;
			target.sv = vsize;
			target.x1 = (target.mysquare==sq1) ? sq1x : sq2x;
			target.y1 = (target.mysquare==sq1) ? sq1y : sq2y;
			target.x2 = target.x1 + hsize;
			target.y2 = target.y1 + vsize;
			evt.onMouseMove = function(ev) {
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
				// indicate that the stage should be updated on the next tick:
				update = true;
			};
			// optimize for iPad
			isdown = true;
			evt.onMouseUp = function (ev) {
				isdown = false;
			}
		};
		target.onMouseOver = function() {
			target.over = true;
			update = true;
		};
		target.onMouseOut = function() {
			target.over = false;
			update = true;
		};
	})(corner_sprites[1]);
	(function(target) {
		target.onPress = function(evt) {
			if (!previewActive) {
				previewActive = true;
				update = true;
			}

			// drag
			// save mouse position for future reference
			target.mx = stage.mouseX - target.x;
			target.my = stage.mouseY - target.y;
			target.sh = hsize;
			target.sv = vsize;
			target.x1 = (target.mysquare==sq1) ? sq1x : sq2x;
			target.y1 = (target.mysquare==sq1) ? sq1y : sq2y;
			target.x2 = target.x1 + hsize;
			target.y2 = target.y1 + vsize;
			evt.onMouseMove = function(ev) {
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
				// indicate that the stage should be updated on the next tick:
				update = true;
			};
			// optimize for iPad
			isdown = true;
			evt.onMouseUp = function (ev) {
				isdown = false;
			}
		};
		target.onMouseOver = function() {
			target.over = true;
			update = true;
		};
		target.onMouseOut = function() {
			target.over = false;
			update = true;
		};
	})(corner_sprites[2]);
	(function(target) {
		target.onPress = function(evt) {
			if (!previewActive) {
				previewActive = true;
				update = true;
			}

			// drag
			// save mouse position for future reference
			target.mx = stage.mouseX - target.x;
			target.my = stage.mouseY - target.y;
			target.sh = hsize;
			target.sv = vsize;
			target.x1 = (target.mysquare==sq1) ? sq1x : sq2x;
			target.y1 = (target.mysquare==sq1) ? sq1y : sq2y;
			target.x2 = target.x1 + hsize;
			target.y2 = target.y1 + vsize;
			evt.onMouseMove = function(ev) {
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
				// indicate that the stage should be updated on the next tick:
				update = true;
			};
			// optimize for iPad
			isdown = true;
			evt.onMouseUp = function (ev) {
				isdown = false;
			}
		};
		target.onMouseOver = function() {
			target.over = true;
			update = true;
		};
		target.onMouseOut = function() {
			target.over = false;
			update = true;
		};
	})(corner_sprites[3]);
	(function(target) {
		target.onPress = function(evt) {
			if (!previewActive) {
				previewActive = true;
				update = true;
			}

			// drag
			// save mouse position for future reference
			target.mx = stage.mouseX - target.x;
			target.my = stage.mouseY - target.y;
			target.sh = hsize;
			target.sv = vsize;
			target.x1 = (target.mysquare==sq1) ? sq1x : sq2x;
			target.y1 = (target.mysquare==sq1) ? sq1y : sq2y;
			target.x2 = target.x1 + hsize;
			target.y2 = target.y1 + vsize;
			evt.onMouseMove = function(ev) {
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
				// indicate that the stage should be updated on the next tick:
				update = true;
			};
			// optimize for iPad
			isdown = true;
			evt.onMouseUp = function (ev) {
				isdown = false;
			}
		};
		target.onMouseOver = function() {
			target.over = true;
			update = true;
		};
		target.onMouseOut = function() {
			target.over = false;
			update = true;
		};
	})(corner_sprites[4]);
	(function(target) {
		target.onPress = function(evt) {
			if (!previewActive) {
				previewActive = true;
				update = true;
			}

			// drag
			// save mouse position for future reference
			target.mx = stage.mouseX - target.x;
			target.my = stage.mouseY - target.y;
			target.sh = hsize;
			target.sv = vsize;
			target.x1 = (target.mysquare==sq1) ? sq1x : sq2x;
			target.y1 = (target.mysquare==sq1) ? sq1y : sq2y;
			target.x2 = target.x1 + hsize;
			target.y2 = target.y1 + vsize;
			evt.onMouseMove = function(ev) {
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
				// indicate that the stage should be updated on the next tick:
				update = true;
			};
			// optimize for iPad
			isdown = true;
			evt.onMouseUp = function (ev) {
				isdown = false;
			}
		};
		target.onMouseOver = function() {
			target.over = true;
			update = true;
		};
		target.onMouseOut = function() {
			target.over = false;
			update = true;
		};
	})(corner_sprites[5]);
	(function(target) {
		target.onPress = function(evt) {
			if (!previewActive) {
				previewActive = true;
				update = true;
			}

			// drag
			// save mouse position for future reference
			target.mx = stage.mouseX - target.x;
			target.my = stage.mouseY - target.y;
			target.sh = hsize;
			target.sv = vsize;
			target.x1 = (target.mysquare==sq1) ? sq1x : sq2x;
			target.y1 = (target.mysquare==sq1) ? sq1y : sq2y;
			target.x2 = target.x1 + hsize;
			target.y2 = target.y1 + vsize;
			evt.onMouseMove = function(ev) {
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
				// indicate that the stage should be updated on the next tick:
				update = true;
			};
			// optimize for iPad
			isdown = true;
			evt.onMouseUp = function (ev) {
				isdown = false;
			}
		};
		target.onMouseOver = function() {
			target.over = true;
			update = true;
		};
		target.onMouseOut = function() {
			target.over = false;
			update = true;
		};
	})(corner_sprites[6]);
	(function(target) {
		target.onPress = function(evt) {
			if (!previewActive) {
				previewActive = true;
				update = true;
			}

			// drag
			// save mouse position for future reference
			target.mx = stage.mouseX - target.x;
			target.my = stage.mouseY - target.y;
			target.sh = hsize;
			target.sv = vsize;
			target.x1 = (target.mysquare==sq1) ? sq1x : sq2x;
			target.y1 = (target.mysquare==sq1) ? sq1y : sq2y;
			target.x2 = target.x1 + hsize;
			target.y2 = target.y1 + vsize;
			evt.onMouseMove = function(ev) {
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
				// indicate that the stage should be updated on the next tick:
				update = true;
			};
			// optimize for iPad
			isdown = true;
			evt.onMouseUp = function (ev) {
				isdown = false;
			}
		};
		target.onMouseOver = function() {
			target.over = true;
			update = true;
		};
		target.onMouseOut = function() {
			target.over = false;
			update = true;
		};
	})(corner_sprites[7]);
}

function draw() {
	if (drawMode=="normal") {
		clearGrid();
		drawBackground();
		drawVertical();
		drawSquare(sq1, sq1x, sq1y);
		drawSquare(sq2, sq2x, sq2y);
		drawCorners();
		drawText();
	} else {
		clearBackground();
		clearVertical();
		clearSquares();
		clearCorners();
		drawGrid();
	}
	drawRotate();
}

function clearGrid() {
	grid.graphics.clear();
}

function drawGrid() {
	var g = grid.graphics;
	var i;
	var cols = 17;
	var rows = 14;
	var colgap = (img.width/cols);
	var rowgap = (img.height/rows);
	var h = img.height;
	var w = img.width;
	
	g.clear();
	g.setStrokeStyle(1, "round", "round");
	g.beginStroke(COLOR);
	for (i=1;i<cols;++i) {
		g.moveTo(i*colgap,0).lineTo(i*colgap,stageHeight-60);
	}
	for (i=1;i<rows;++i) {
		g.moveTo(0,i*rowgap).lineTo(stageWidth,i*rowgap);
	}
}

function rotateImage() {
	bmp.rotation = imageRotation;
	var radians = imageRotation * (Math.PI/180);
	var newx = Math.sin(radians) * img.height;
	var newy = Math.sin(radians) * img.width;
	if (imageRotation>0) bmp.x = newx + OFFSET;
	if (imageRotation<0) bmp.y = -newy;
}

function drawRotate() {
	var g;
	if (drawMode=="rotate") {
		// TEXT
		rotateText.visible = true;
		
		// LEFT
		g = rotateLeftBtn.graphics;
		g.clear();
		g.setStrokeStyle(THICK, "round", "round");
		if (rotateLeftBtn.over) {
			g.beginStroke(OVERCOLOR);
		} else {
			g.beginStroke(COLOR);
		}
		g.beginFill(FILLALPHA);
		g.drawRect(0,0,rotateSize,rotateSize);
		g.moveTo(20,25).lineTo(20,10).lineTo(5,10).lineTo(10,5).moveTo(5,10).lineTo(10,15);

		// RIGHT
		g = rotateRightBtn.graphics;
		g.clear();
		g.setStrokeStyle(THICK, "round", "round");
		if (rotateRightBtn.over) {
			g.beginStroke(OVERCOLOR);
		} else {
			g.beginStroke(COLOR);
		}
		g.beginFill(FILLALPHA);
		g.drawRect(0,0,rotateSize,rotateSize);
		g.moveTo(10,25).lineTo(10,10).lineTo(25,10).lineTo(20,5).moveTo(25,10).lineTo(20,15);
		
		// MODE BUTTON
		modeText.text = "edit mode";
		modeText.x = 305;
		modeBtn.x = 300;
		g = modeBtn.graphics;
		g.clear();
		g.setStrokeStyle(THICK, "round", "round");
		if (modeBtn.over) {
			g.beginStroke(OVERCOLOR);
		} else {
			g.beginStroke(COLOR);
		}
		g.beginFill(FILLALPHA);
		g.drawRect(0,0,90,rotateSize);
	} else {
		rotateText.visible = false;
		
		// LEFT
		g = rotateLeftBtn.graphics;
		g.clear();
		
		// RIGHT
		g = rotateRightBtn.graphics;
		g.clear();
		
		// MODE BUTTON
		modeText.text = "rotate mode";
		modeText.x = 15;
		modeBtn.x = 10;
		g = modeBtn.graphics;
		g.clear();
		g.setStrokeStyle(THICK, "round", "round");
		if (modeBtn.over) {
			g.beginStroke(OVERCOLOR);
		} else {
			g.beginStroke(COLOR);
		}
		g.beginFill(FILLALPHA);
		g.drawRect(0,0,110,rotateSize);
	}
}

function drawText()	{
	if (sq1.over) {
		// text
		txt.x = sq1x + hsize*.5 - txt.lineWidth;
		txt.y = sq1y + vsize*.5;
	} else if (sq2.over) {
		// text
		txt.x = sq2x + hsize*.5 + INSET;
		txt.y = sq2y + vsize*.5;
	} else {
		// text
		txt.x = -1000;
		txt.y = -1000;
	}
	if (vert_sprite.over) {
		// text
		vtxt.x = vertx - vtxt.lineWidth*.5;
		vtxt.y = sq1y + vsize + 30;
		if (vtxt.y > stageHeight - 30) {
			vtxt.y = sq1y + vsize - 30;
		}
	} else {
		// text
		vtxt.x = -1000;
	}
}

function clearBackground() {
	bg.graphics.clear();
}

function drawBackground() {
	var g = bg.graphics;
	g.clear();
	g.beginStroke(null);
	g.beginFill(BACKALPHA);
	g.drawRect(0,0,stageWidth,sq1y);
	g.drawRect(0,sq1y,sq1x,vsize);
	//g.drawRect(sq1x+hsize,sq1y,(vertx-sq1x-hsize)*2,vsize);
	g.drawRect(sq2x+hsize,sq1y,stageWidth-(sq2x+hsize),vsize);
	g.drawRect(0,sq1y+vsize,stageWidth,stageHeight-vsize-sq1y);
}

function clearVertical() {
	vert_sprite.graphics.clear();
}

function drawVertical() {
	vert_sprite.x = vertx;
	var g = vert_sprite.graphics;
	g.clear();
	g.setStrokeStyle(THICK, "round", "round");
	if (!vert_sprite.over) {
		vert_sprite.graphics.beginStroke(COLOR);
	} else {
		vert_sprite.graphics.beginStroke(OVERCOLOR);
	}
	g.beginFill(FILLALPHA);
	g.drawRect(-(VERTWIDTH*.5),-(VERTHEIGHT*.5),VERTWIDTH,VERTHEIGHT);
	g.moveTo(0,-(VERTHEIGHT*.5)).lineTo(0, -stageHeight).moveTo(0,(VERTHEIGHT*.5)).lineTo(0, stageHeight);
	g.moveTo(-(VERTWIDTH*.5),0).lineTo(-(VERTWIDTH*.5),VERTWIDTH*.5).lineTo(-VERTWIDTH,0).lineTo(-(VERTWIDTH*.5),-(VERTWIDTH*.5)).lineTo(-(VERTWIDTH*.5),0);
	g.moveTo((VERTWIDTH*.5),0).lineTo((VERTWIDTH*.5),VERTWIDTH*.5).lineTo(VERTWIDTH,0).lineTo((VERTWIDTH*.5),-(VERTWIDTH*.5)).lineTo((VERTWIDTH*.5),0);
}

function clearCorners() {
	var i;
	for (i=0;i<8;++i) {
		corner_sprites[i].graphics.clear();
	}
}

function drawCorners() {
	var x = -1000
	var y = -1000;
	var i, crnr;
	for (i=0;i<8;++i) {
		crnr = corner_sprites[i];
		crnr.graphics.clear();
		if (!crnr.over) {
			crnr.graphics.beginStroke(COLOR);
		} else {
			crnr.graphics.beginStroke(OVERCOLOR);
		}
		crnr.graphics.beginFill(FILLALPHA);
		crnr.graphics.setStrokeStyle(THICK, "round", "round");
		crnr.graphics.drawRect(-CORNER_OFFSET,-CORNER_OFFSET,CORNER_OFFSET+CORNER_OFFSET,CORNER_OFFSET+CORNER_OFFSET);
		if (crnr.mysquare==sq1) {
			x = sq1x;
			y = sq1y;
		} else if (crnr.mysquare==sq2) {
			x = sq2x;
			y = sq2y;
		}
		crnr.x = x+CORNER_OFFSET+((hsize-CORNER_OFFSET-CORNER_OFFSET)*crnr.xfactor);
		crnr.y = y+CORNER_OFFSET+((vsize-CORNER_OFFSET-CORNER_OFFSET)*crnr.yfactor);
	}
}

function clearSquares() {
	sq1.graphics.clear();
	sq2.graphics.clear();
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
		g.moveTo(x-CROSSSIZE+hsize*.5,y-CROSSSIZE+vsize*.5).lineTo(x+CROSSSIZE+hsize*.5,y+CROSSSIZE+vsize*.5).moveTo(x+CROSSSIZE+hsize*.5,y-CROSSSIZE+vsize*.5).lineTo(x-CROSSSIZE+hsize*.5,y+CROSSSIZE+vsize*.5);
		// draw arrows
		g.moveTo(x-CROSSSIZE+hsize*.5,(y-CROSSSIZE+vsize*.5)+(CROSSSIZE*.5)).lineTo(x-CROSSSIZE+hsize*.5,y-CROSSSIZE+vsize*.5).lineTo(x-CROSSSIZE+hsize*.5+(CROSSSIZE*.5),y-CROSSSIZE+vsize*.5);
		g.moveTo(x+CROSSSIZE+hsize*.5,y+CROSSSIZE+vsize*.5-(CROSSSIZE*.5)).lineTo(x+CROSSSIZE+hsize*.5,y+CROSSSIZE+vsize*.5).lineTo(x+CROSSSIZE+hsize*.5-(CROSSSIZE*.5),y+CROSSSIZE+vsize*.5);
		g.moveTo(x+CROSSSIZE+hsize*.5,y-CROSSSIZE+vsize*.5+(CROSSSIZE*.5)).lineTo(x+CROSSSIZE+hsize*.5,y-CROSSSIZE+vsize*.5).lineTo(x+CROSSSIZE+hsize*.5-(CROSSSIZE*.5),y-CROSSSIZE+vsize*.5);
		g.moveTo(x-CROSSSIZE+hsize*.5,y+CROSSSIZE+vsize*.5-(CROSSSIZE*.5)).lineTo(x-CROSSSIZE+hsize*.5,y+CROSSSIZE+vsize*.5).lineTo(x-CROSSSIZE+hsize*.5+(CROSSSIZE*.5),y+CROSSSIZE+vsize*.5);
	} else {
		g.beginStroke(COLOR);
		g.moveTo(x-CROSSSIZE+hsize*.5,y-CROSSSIZE+vsize*.5).lineTo(x+CROSSSIZE+hsize*.5,y+CROSSSIZE+vsize*.5).moveTo(x+CROSSSIZE+hsize*.5,y-CROSSSIZE+vsize*.5).lineTo(x-CROSSSIZE+hsize*.5,y+CROSSSIZE+vsize*.5);
	}
}

function tick() {
	// only draw once clicked
	if (previewActive && drawMode=="normal") {
		$("#previewExplain").hide();
		$("#btnNext").show();
	}
	if (update) {
		console.log(imageRotation);
		draw();
		update = false; // only update once
		updatePreview();
		stage.update();
		if (previewActive && mode=="ANAGLYPH" && drawMode=="normal") {
			drawAnaglyph();
		}
	}
	if (previewActive && mode=="GIF" && drawMode=="normal") {
		drawGIF();
	}
	if (drawMode=="rotate") {
		document.getElementById("previewGIF").style.display = "none";
		document.getElementById("previewAnaglyph").style.display = "none";
		$("#previewExplain").show();
		$("#btnNext").hide();
		$("#previewExplain").text("Preview will be created once you exit rotate mode");
	}
}

function updatePreview() {
	var p = document.getElementById("previewGIF");
	p.style.width = hsize + "px";
	p.style.height = vsize + "px";
}

function toggleMode(m) {
	mode = m;
	var togglerDiv = $("#toggler");
	var gifDiv = $("#toggleGIF");
	var anaDiv = $("#toggleAna");
	var linksDiv = $("#toggleLinks");
	var extraDiv = $("#GIFExtraLinks");
	if (m=="GIF") {
		togglerDiv.removeClass("anaglyphActive"); 
		togglerDiv.addClass("GIFActive"); 
		anaDiv.removeClass("active"); 
		gifDiv.addClass("active"); 
		extraDiv.show(); 
	} else {
		update = true;
		togglerDiv.addClass("anaglyphActive"); 
		togglerDiv.removeClass("GIFActive"); 
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
		lR = leftimgdata_array[i];
		lG = leftimgdata_array[i+1];
		lB = leftimgdata_array[i+2];
		// left (RED) operation
		lR = 255;
		lG = 255 - (255 - leftimgdata_array[i+1]);
		lB = 255 - (255 - leftimgdata_array[i+2]);
		// right (CYAN) operation
		rightimgdata_array[i] = rightimgdata_array[i];
		rightimgdata_array[i+1] = lG;
		rightimgdata_array[i+2] = lB;
	}

	// Write the MULTIPLIED image data to the canvas
	ctx3D.putImageData(rightimgdata, 0, 0);
}

function loadPhoto(str) {
	index = str;
	console.log("photo");
	img.onload = handleImageLoad;
	img.onerror = handleImageError;
	var url = "http://images.nypl.org/index.php?id="+index+"&t=w";
	img = new Image();
	img.src = url;
	
	getImageFromServer();
}

function getImageFromServer() {
	// for the gif
	var url = "/getimagedata.jpeg?r="+imageRotation+"&url="+index;
	var p = document.getElementById("previewGIF");
	p.style.background = "url('"+url+"') no-repeat -10000px -10000px";
	// for the anaglyph
	$.getImageData({
		  url: index,
		  server: "/getimagedata/?r="+imageRotation+"&callback=?",
		  success: function(image){
			// Set up the canvas
			ctx3D = resultcanvas.getContext('2d');
			ctxbase = processcanvas.getContext('2d');
			
			// Draw the image on to the BASE canvas
			ctxbase.drawImage(image, 0, 0, image.width, image.height);
			handleImageLoad(image);
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
	if (previewActive) {
		console.log("generating...");
		document.getElementById("btnNext").disabled = true;
		document.getElementById("btnNext").onclick = {};
		$("#btnNext").replaceWith("<div class=\"generator\">GENERATING...</div>");
		// send google analytics
		_gaq.push(['_trackEvent', 'Granimations', mode, "HTML"]);
		// post to server
		$.ajax({
			url: "/animations/createJson.json",
			dataType: 'json',
			data: {
				x1:Math.round(sq1x-OFFSET),
				y1:Math.round(sq1y),
				x2:Math.round(sq2x-OFFSET),
				y2:Math.round(sq2y),
				height:Math.round(vsize),
				width:Math.round(hsize),
				delay:Math.round(speed),
				digitalid:index,
				rotation:imageRotation,
				mode:mode,
				creator:"mga"
					},
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
			  },
			  429: function() {
				  alert('Too many requests (429)');
			  },
			  500: function() {
				  alert('Internal server error (500)');
			  }
			}
		});
	}
}

function generateFromFlash(_sq1x,_sq1y,_sq2x,_sq2y,_hsize,_vsize,_speed,_index,_mode) {
	// send google analytics
	_gaq.push(['_trackEvent', 'Granimations', _mode, "FLASH"]);
	$.ajax({
		url: "/animations/createJson/"+Math.round(_sq1x)+"/"+Math.round(_sq1y)+"/"+Math.round(_sq2x)+"/"+Math.round(_sq2y)+"/"+Math.round(_hsize)+"/"+Math.round(_vsize)+"/"+Math.round(_speed)+"/"+_index+"/"+_mode+"/mga.json",
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
		  },
		  429: function() {
			  alert('Too many requests (429)');
		  },
		  500: function() {
			  alert('Internal server error (500)');
		  }
		}
	});
}

function searchImages() {
	if ($("#search .query").val()!="") {
		// post to server
		$("#search .status").text("Searching...");
		$.ajax({
			url: "/choose/"+$("#search .query").val(),
			dataType: 'json',
			data: null,
			success: function(data) {
				if (data.length>0) {
					// clean the array
					image_array = data;
					$("#search .status").text("Found " + data.length + " result" + (data.length>1?"s":"") + ".");
					refreshImages();
				} else {
					$("#search .status").text("No results :-( Try a different keyword.");
				}
			},
			statusCode: {
			  404: function() {
				  alert('Photo not found error (404)');
			  },
			  429: function() {
				  alert('Too many requests (429)');
			  },
			  500: function() {
				  alert('Internal server error (500)');
			  }
			}
		});
	} else {
		$("#search .status").text("Please type a keyword.");
	}
}

function initSearch() {
	$(document).keypress(function(e) {
	    if(e.keyCode == 13 && $("#search .query").val()!="") {
	    	searchImages();
	    }
	});
}

function initGallerySearch() {
	$(document).keypress(function(e) {
	    if(e.keyCode == 13 && $("#search .query").val()!="") {
	    	searchGallery();
	    }
	});
}

function searchGallery() {
	if ($("#search .query").val()!="") {
		window.location.href = "/gallery/?q="+$("#search .query").val();
		$("#search .status").text("Searching...");
	} else {
		$("#search .status").text("Please type a keyword.");
	}
}

function refreshImages() {
	if (image_array.length>0) {
		clearImages();
		var r = image_array.sort(function(){ 
			return Math.round(Math.random())-0.5
		}).slice(0,9)
		var i, l = r.length;
		var url, href;
		for (i=0;i<l;++i) {
			url = "http://images.nypl.org/index.php?id="+r[i]+"&t=r";
			href = "/convert/" + r[i];
			$("#st" + i).toggleClass("stereograph");
			$("#st" + i).toggleClass("stereographPlain");
			$("#link_" + i).show();
			$("#linko_" + i).show();
			$("#link_" + i).attr("href",href);
			$("#linko_" + i).attr("href",href);
			$("#img_" + i).attr("src",url);
		}
	}
}

function clearImages() {
	$(".stereograph").toggleClass("stereographPlain");
	$(".stereograph").toggleClass("stereograph");
	var i;
	var url, href;
	for (i=0;i<9;++i) {
		url = "/assets/blank.png";
		$("#link_" + i).hide();
		$("#linko_" + i).hide();
		$("#img_" + i).attr("src",url);
	}
}

function handleImageLoad(e) {
	imagesLoaded++;
	if (imagesLoaded==2) {
		run();
		addInteractivity();
		update = true;
	}
}

//called if there is an error loading the image (usually due to a 404)
function handleImageError(e) {
    console.log("Error Loading Image : " + e.target.src);
}

function toggleInstructions() {
	if (helpVisible) {
		helpVisible = false;
		$(".instructions").width(1200);
		$(".instructions").height(540);
		$(".instructions").animate({
			width: 0,
			height: 0
		}, 500, 'swing', function () {
			$(".showInstructions").show();
		});
	} else {
		helpVisible = true;
		$(".instructions").width(0);
		$(".instructions").height(0);
		$(".showInstructions").hide();
		$(".instructions").animate({
			width: 1200,
			height: 540
		}, 1500, 'swing');
	}
}

function disableCanvas() {
	$("#yescanvas").hide();
	$("#nocanvas").show();
	toggleInstructions();
}