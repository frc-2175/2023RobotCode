// line vector - the big lines created when you click somewhere
// point - small points spaced about an inch apart that show up on each line vector;
// 		 these are mostly just for show on the maker and then used in pure pursuit in the robot code
// trigger point - these are user-specified points across our path, sitting on a chosen line vector,
//		 that will trigger a certain action at a part along the path

// eslint-disable-next-line no-undef
disableFriendlyErrors = true;

/** Class representing a vector. */
class Vector {
	/**
	 * Create a Vector
	 * @param {number} x
	 * @param {number} y
	 */
	constructor(x, y) {
		this.x = x;
		this.y = y;
	}

	distTo(vector) {
		return dist(...this, ...vector);
	}

	add(vector) {
		vector = typeof vector === "number" ? new Vector(vector, vector) : vector;
		return new Vector(this.x + vector.x, this.y + vector.y);
	}

	sub(vector) {
		vector = typeof vector === "number" ? new Vector(vector, vector) : vector;
		return new Vector(this.x - vector.x, this.y - vector.y);
	}

	div(vector) {
		vector = typeof vector === "number" ? new Vector(vector, vector) : vector;
		return new Vector(this.x / vector.x, this.y / vector.y);
	}

	mul(vector) {
		vector = typeof vector === "number" ? new Vector(vector, vector) : vector;
		return new Vector(this.x * vector.x, this.y * vector.y);
	}

	toScreen() {
		return new Vector(
			imageCenter.x + this.x / pixelToInchRatio,
			imageCenter.y + this.y / -pixelToInchRatio,
		);
	}

	toField() {
		return new Vector(
			-round((imageCenter.x - this.x) * pixelToInchRatio),
			round((imageCenter.y - this.y) * pixelToInchRatio),
		);
	}

	* [Symbol.iterator]() {
		yield this.x;
		yield this.y;
	}
}

let img,
	/** @type {number} */
	pixelToInchRatio,
	/** @type {number} */
	imageCenter,
	/** @type {number} */
	previousTriggerPointCount,
	/** @type {boolean} */
	lineVectorHasChanged,
	/** @type {Vector} */
	mouseVector,
	/** @type {Vector} */
	fieldMouse;
/** @type {Vector[]} */
const points = [];
/** @type {Vector[]} */
const lineVectors = [];
/** @type {number} */
const pointFreq = 10;
/** @type {{vector: Vector, name: string, color: Object, segment: number}[]} */
const triggerPoints = [];
let cnv;

const colorList = [
	{
		name: "red",
		value: "ff595e",
	},
	{
		name: "scarlet",
		value: "ff5500",
	},
	
	{
		name: "orange",
		value: "ff924c",
	},
	{
		name: "bannnnnnnana",
		value: "ffea00",
	},
	{
		name: "yellow",
		value: "ffca3a",
	},
	{
		name: "green",
		value: "8ac926",
	},
	{
		name: "aqua",
		value: "52e3e1",
	},
	{
		name: "blue",
		value: "0061e0",
	},
	{
		name: "purple",
		value: "7161ef",
	},
	{
		name: "bink",
		value: "ff7b9c",
	},
];

// sets up field image as background
// eslint-disable-next-line no-unused-vars
function preload() {
	img = loadImage("rapidreactfield.png");
}

// sets up coordinates of cursor & displays them
// eslint-disable-next-line no-unused-vars
function setup() {
	cnv = createCanvas(windowWidth, (windowWidth * 0.58));
	imageCenter = new Vector(width / 2, height / 2);
	pixelToInchRatio = 1.37 / (width / (2987 / 5));
	textSize(15);
}

//
function canvasFocused() {
	return mouseY > 0 && mouseY < (windowWidth * 0.58) && mouseX > 0 && mouseX < windowWidth;
}


/**
 * gets the distance from start of list to a specified trigger point in the list
 * @param {*} lvIndex index of lineVector that tp lies on
 * @param {*} tpVector point/vector that triggerPoint is (location of TP)
 */
function totalDist(lvIndex, tpVector) {
	// const lvFragmentDistance = getClosestPointOnLines(tpVector,lineVectors).fTo * endLineVector.length;
	const endLineVector = lineVectors[lvIndex];
	let total = 0; // total distance up to specified triggerPoint
	const remainingDistance = endLineVector.distTo(tpVector);

	for (let i = 0; i < lvIndex; i++) { // adding up all of the linevectors up to the specified one before our end TP
		total += lineVectors[i].distTo(lineVectors[i + 1]);
	}

	total += remainingDistance; // add distance to end vector

	return total;
}

function createNewLineVector(vector) {
	lineVectors.push(vector);
	lineVectorHasChanged = true;
	updateTitle(pointFile, true);
}

function createNewPoint(vector) {
	points.push(vector);
}

/**
 * removes the most recently made line vector & any trigger points on it
 */
function removeLastLineVector() {
	// if there is more than 1
	if (lineVectors.length > 1) {
		const previousLineVector = lineVectors[lineVectors.length - 2];
		const currentLineVector = lineVectors[lineVectors.length - 1];
		const length = previousLineVector.distTo(currentLineVector);
		points.splice(-length);

		document.getElementById("triggerPointDiv").innerHTML = "";
		previousTriggerPointCount = 0;


		for (let i = 0; i < triggerPoints.length; i++) { // deleting all related trigger points to the line vector being deleted
			if (triggerPoints[i].segment === (lineVectors.length - 2)) {
				triggerPoints.splice(i, 1);
				i--;
			}
		}
		lineVectors.pop();
		updateTitle(pointFile, true);
	}
}

// eslint-disable-next-line no-unused-vars
function mouseClicked() {
	if (canvasFocused() && !isMouseOverTriggerPoint().isMouseOver) {
		createNewLineVector((new Vector(mouseX, mouseY)).toField());
	}
}


function checkDraggingTriggerPoint() {
	const nearestTriggerPoint = isMouseOverTriggerPoint();
	const closestPoint = getClosestPointOnLines(fieldMouse, lineVectors).vector;
	if (nearestTriggerPoint.isMouseOver) {
		nearestTriggerPoint.triggerPoint.vector = closestPoint;
	}
}




// controls:
// s - save points
// o - open saved points
// space key - creates a trigger point
// backspace key - deletes last segment of path
document.addEventListener("keydown", (e) => {
	if (canvasFocused()) {
		if (e.key === "s" || e.key === "S") {
			e.preventDefault();
			savePoints();
		}

		if (e.key === "o" || e.key === "O") {
			e.preventDefault();
			openPoints();
		}

		if (e.key === " ") {
			const closestPoint = getClosestPointOnLines(fieldMouse, lineVectors).vector;
			const closestSegment = getClosestPointOnLines(fieldMouse, lineVectors).i - 1;
			e.preventDefault();
			createTriggerPoint(closestPoint, "unnamed", nextColor().value, closestSegment);
		}

		if (e.key === "Backspace") {
			removeLastLineVector();
		}
	}
}, false);

function updateTitle(handle, dataChangedSinceSave) {
	try {
		if (dataChangedSinceSave) {
			document.title = "*" + handle.name;
		} else {
			document.title = handle.name;
		}
	} catch {
		// console.error("File not selected yet.");
	}
}

let lastColor = -1;
function nextColor() {
	lastColor = (lastColor + 1) % colorList.length;
	return colorList[lastColor];
}

async function getNewFileHandle() {
	const options = {
		types: [
			{
				description: "Pure Pursuit Path File",
				accept: {
					"text/plain": [".path"],
				},
			},
		],
	};
	const handle = await window.showSaveFilePicker(options);
	return handle;
}

async function writeFileToDisk(fileHandle, contents) {
	// Create a FileSystemWritableFileStream to write to.
	const writable = await fileHandle.createWritable();
	// Write the contents of the file to the stream.
	await writable.write(contents);
	// Close the file and write the contents to disk.
	await writable.close();
}

let pointFile;
/**
 * saves all points & trigger points
 */
async function savePoints() {
	for (let i = 0; i < triggerPoints.length; i++) {
		triggerPoints[i].name = document.getElementById(i).value;
	}
	if (pointFile === undefined) {
		const fileHandle = await getNewFileHandle();
		updateTitle(fileHandle, false);
		writeFileToDisk(fileHandle, JSON.stringify({ points, lineVectors, triggerPoints }));
		pointFile = fileHandle;
	} else {
		updateTitle(pointFile, false);
		writeFileToDisk(pointFile, JSON.stringify({ points, lineVectors, triggerPoints }));
	}
}

async function openPoints() {
	if (!confirm("This will erase your current file!!!")) {
		return;
	}

	const [fileHandle] = await window.showOpenFilePicker();
	const file = await fileHandle.getFile();
	const contents = JSON.parse(await file.text());
	console.log(contents);
	lineVectors.length = 0;
	points.length = 0;
	triggerPoints.length = 0;
	for (const lineVector of contents.lineVectors) {
		lineVectors.push(new Vector(lineVector.x, lineVector.y));
	}
	for (const point of contents.points) {
		points.push(new Vector(point.x, point.y));
	}

	for (const { vector, name, color, segment, distance } of contents.triggerPoints) {
		triggerPoints.push({ vector: new Vector(vector.x, vector.y), name, color, segment, distance });
	}

	const lastTriggerPointColor = contents.triggerPoints[contents.triggerPoints.length - 1].color;
	
	for (let i = 0; i< colorList.length; i++) {
		if (colorList[i].value === lastTriggerPointColor) {
			lastColor = i;
		}
	}
}

/**
 *
 * @typedef {Object} closestPoint
 * @property {Vector} vector Vector of closest point
 * @property {number} i Index of closest point along lines
 * @property {number} fTo Distance scaled 0-1 of closest point along line segment
 */

/**
 * gets the closest point to a singular point/vector on a specified lineVector
 * @param {Vector} point
 * @param {Vector[]} lines list of points representing a line
 * @returns {closestPoint}
 */
function getClosestPointOnLines(point, lines) {
	let fTo, i, dist, minDist, vector;

	for (let n = 1; n < lines.length; n++) {
		if (lines[n].x !== lines[n - 1].x) {
			const a = (lines[n].y - lines[n - 1].y) / (lines[n].x - lines[n - 1].x);
			const b = lines[n].y - a * lines[n].x;
			dist = Math.abs(a * point.x + b - point.y) / Math.sqrt(a * a + 1);
		} else {
			dist = Math.abs(point.x - lines[n].x);
		}

		/** length of line segment */
		const rl = lines[n].distTo(lines[n - 1]);
		/** distance of pt to end line segment */
		const ln = point.distTo(lines[n]);
		/** distance of pt to begin line segment */
		const lnm1 = point.distTo(lines[n - 1]);
		/** calculated length of line segment */
		const calcrl = ln + lnm1 - dist;

		// redefine minimum distance to line segment (not infinite line) if necessary
		if (calcrl > rl) dist = Math.min(ln, lnm1);

		if (minDist === undefined || minDist > dist) {
			if (calcrl > rl) {
				if (lnm1 < ln) { // nearer to previous point
					fTo = 0;
				} else { // nearer to current point
					fTo = 1;
				}
			} else { // perpendicular from point intersects line segment
				fTo = Math.sqrt(lnm1 ** 2 - dist ** 2) / rl;
			}
			minDist = dist;
			i = n;
		}

		const d = lines[i - 1].sub(lines[i]);
		vector = lines[i - 1].sub(d.mul(fTo));
	}

	return { vector, i, fTo };
}

// makes a trigger point
// point - closest point
// segment - closest path segment
/**
 *
 * @param {Vector} vector Point at which to make the triggerPoint
 * @param {string} name Name of the triggerPoint
 * @param {Object} color Color of triggerPoint
 * @param {number} segment Index along list of line vectors that the triggerPoint sits on.
 */
function createTriggerPoint(vector, name, color, segment) {
	const closestPoint = getClosestPointOnLines(fieldMouse, lineVectors).vector;
	if (closestPoint.distTo(mouseVector.toField()) < 50) { // if the distacne to the mouse on the field is less than 50
		const distance = totalDist(segment, vector); // find the distance to the line segment point lies on
		// add to list this trigger point
		triggerPoints.push({ vector, name, color, segment, distance });
	}
}

// /** TODO : Make this a thing
//  * @param {number} index
//  */
// function removeTriggerPoint(index) {
// 	triggerPointList.splice(index, 1);
// }

// eslint-disable-next-line no-unused-vars
function windowResized() {
	resizeCanvas(windowWidth, (windowWidth * 0.58));
	imageCenter = new Vector(width / 2, height / 2);
	pixelToInchRatio = 1.37 / (width / (2987 / 5));
}

function moveTriggerPoint(index, vector) {
	triggerPoints[index].vector = vector;
}

function updateHTML() {
	if (triggerPoints.length > 0) {
		document.getElementById("triggerPointTitle").style.visibility = "visible";
	} else {
		document.getElementById("triggerPointTitle").style.visibility = "hidden";
	}
	const triggerPointDiv = document.getElementById("triggerPointDiv");
	for (let i = previousTriggerPointCount; i < triggerPoints.length; i++) {
		const triggerPointTitle = document.createElement("h4");
		triggerPointTitle.innerHTML = `Trigger point ${i}:`;
		triggerPointTitle.style.color = "#" + triggerPoints[i].color;

		const triggerPointNameInput = document.createElement("input");
		triggerPointNameInput.id = `${i}`;
		triggerPointNameInput.style.zIndex = 999;

		const triggerPointElement = document.createElement("div");
		triggerPointElement.style.display = "inline-block";
		triggerPointElement.appendChild(triggerPointTitle);
		triggerPointElement.appendChild(triggerPointNameInput);

		triggerPointDiv.appendChild(triggerPointElement);
	}
	previousTriggerPointCount = triggerPoints.length;
}

let draggingTriggerPoint = {"isMouseOver": false, "index": null};

function isMouseOverTriggerPoint() {
	if (draggingTriggerPoint.isMouseOver) {
		return draggingTriggerPoint;
	}
	if (draggingTriggerPoint)
		for (i = 0; i < triggerPoints.length; i++) {
			if (triggerPoints[i].vector.distTo(mouseVector.toField()) < 15) {
				draggingTriggerPoint = {"isMouseOver": true, "index": i};
				return draggingTriggerPoint;
			}
		}
	if (!mouseIsPressed) {
		draggingTriggerPoint = {"isMouseOver": false, "index": null};
		return draggingTriggerPoint;
	}
}

// eslint-disable-next-line no-unused-vars
function draw() {
	updateHTML();
	mouseVector = new Vector(mouseX, mouseY);
	fieldMouse = mouseVector.toField();

	console.log(draggingTriggerPoint);

	clear();
	image(img, 0, 0, width, height);
	strokeWeight(0);
	image(img, 0, 0, width, height);
	fill(0);
	document.getElementById("screenCords").innerHTML = round(mouseX) + ", " + round(mouseY);
	document.getElementById("fieldCords").innerHTML = fieldMouse.x + ", " + fieldMouse.y;
	document.getElementById("frameRate").innerHTML = round(frameRate());
	
	if (lineVectors.length > 0) {
		document.getElementById("segmentLength").innerHTML = round(lineVectors[lineVectors.length - 1].distTo(fieldMouse));
	} else {
		document.getElementById("segmentLength").innerHTML = "";
	}

	if (lineVectors.length > 0) { // grey line to mouse.
		stroke(150);
		strokeWeight(2);
		line(...lineVectors[lineVectors.length - 1].toScreen(), ...mouseVector);
	}

	if (lineVectors.length > 1) {
		const previousPoint = lineVectors[lineVectors.length - 2];
		const currentPoint = lineVectors[lineVectors.length - 1];
		const length = previousPoint.distTo(currentPoint);
		const stepSize = (currentPoint.sub(previousPoint)).div(length);
		const closestPoint = getClosestPointOnLines(fieldMouse, lineVectors).vector;

		strokeWeight(12);
		point(...closestPoint.toScreen());

		stroke(0);
		strokeWeight(8);
		if (lineVectorHasChanged) {
			for (let dotCount = 0; dotCount < length; dotCount++) {
				createNewPoint(previousPoint.add(stepSize.mul(dotCount)));
			}
		}

		noFill();
		strokeWeight(2);
		beginShape();
		for (let i = 0; i < lineVectors.length; i++) vertex(...lineVectors[i].toScreen());
		endShape();

		strokeWeight(5);
		for (let i = 0; i < points.length; i += pointFreq) {
			point(...points[i].toScreen());
		}

		for (const triggerPoint of triggerPoints) {
			stroke(0);
			strokeWeight(18);
			point(...triggerPoint.vector.toScreen());
			stroke("#" + triggerPoint.color);
			strokeWeight(10);
			point(...triggerPoint.vector.toScreen());
		}

		if (isMouseOverTriggerPoint().isMouseOver) {
			document.body.style.cursor = "move";
		} else {
			document.body.style.cursor = "default";
		}

		lineVectorHasChanged = false;
		cnv.mousePressed(checkDraggingTriggerPoint);
	}
}
 