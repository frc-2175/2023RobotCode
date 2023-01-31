// Log viewer with spacetime map viewing capabilities

// Variables that represent the horizontal (time) axis range
let pageStart = 0;
let pageEnd = 40;
let maxEnd = 40;

// The padding in the vertical direction on all of the graphs
const verticalPadding = 10;

// State variables for the series currently being plotted and a list of all
// of the known data series from the log file
let seriesToPlot = [];
let dataSeries = {};

// State variables for time-axis resizing
let resizing = false;
let mouseStart;

const colors = ["#6ca16a", "#ffa742", "#ba98ed", "#fa6e6e"];
const currentColors = {};

// This runs when the page loads once
window.addEventListener("DOMContentLoaded", () => {
	(async () => {
		// Load all of the matches from the server
		const matches = await loadMatches();
        
		// Populate the match selector with all of the values
		for (const match of matches) {
			const matchOption = document.createElement("option");
			matchOption.setAttribute("value", match);
			matchOption.innerHTML = "Match " + match;
			document.querySelector("#matchSelect").appendChild(matchOption);
		}

		// Load the log file and parse some data out of it
		let logs = await loadMatch(getCurrentMatch());
		let events = getSpacetimeEvents(logs);
		let points = getPointEvents(logs);
		let levels = getLevels(events);
		dataSeries = getDataSeries(logs);
        
		// Update the log viewer when the current match changes
		document.querySelector("#matchSelect").addEventListener("change", async () => {
			logs = await loadMatch(getCurrentMatch());
			events = getSpacetimeEvents(logs);
			points = getPointEvents(logs);
			levels = getLevels(events);
			dataSeries = getDataSeries(logs);
			seriesToPlot = [];
			pageStart = 0;
			pageEnd = maxEnd;
			renderOnResize();
		});
		
		const eventCanvas = setUpCanvas("#eventCanvas", document.body.clientWidth, document.getElementById("topSection").clientHeight);
        
		/**
         * Renders a single spacetime map on screen. Requires the variables
         * above (such as levels)
         * @param {*} events the spacetime events to render on screen
         */
		function renderEvents(events) {
			for (const event of events) {
				const mostParentID = getMostParentID(event, logs);
				let color;
				if (currentColors[mostParentID]) {
					color = currentColors[mostParentID];
				} else {
					color = colors[Object.keys(currentColors).length % (colors.length)];
					currentColors[mostParentID] = color;
				}

				const div = document.createElement("div");
				div.textContent = event.message;
				div.style.position = "absolute";
				div.style.height = "20px";
				div.style.backgroundColor = color;
				div.style.width = `${(event.endTime - event.startTime) / (pageEnd - pageStart) * 100}%`;
				div.style.left = `${(event.startTime - pageStart) / (pageEnd - pageStart) * 100}%`;
				div.style.top = `${30 * levels[event.id]}px`;
				div.style.lineHeight = "20px";
				document.querySelector("#spacetime").appendChild(div);
				renderEvents(event.children);
			}
		}

		function renderPoints(points) {
			for (const point of points) {
				const color = colors[Object.keys(currentColors).length % (colors.length)];
				const div = document.createElement("div");
				div.textContent = point.message;
				div.style.position = "absolute";
				div.style.height = "20px";
				div.style.left = `${(point.time - pageStart) / (pageEnd - pageStart) * 100}%`;
				div.style.top = `${30 * levels[point.id]}px`;
				div.style.lineHeight = "20px";
				div.style.paddingLeft = "5px";
				document.querySelector("#spacetime").appendChild(div);
				const ctx = eventCanvas.getContext("2d");
				const x = (point.time - pageStart) / (pageEnd - pageStart) * eventCanvas.width;
				drawLine(ctx, x, document.querySelector("#topUI").clientHeight + 4, x, eventCanvas.height, 5, color);
			}
		}

		// Render all of the events that were loaded from the log file
		renderEvents(events);
		renderPoints(points);
        
		/** 
         * A function to be called whenever the window is resized
         */
		function renderOnResize() {
			document.querySelector("#spacetime").innerHTML = "";

			renderEvents(events);
			renderTopBar();

			seriesToPlot.forEach(series => series.canvas.setAttribute("width", document.body.clientWidth));
			refresh();
			setUpCanvas("#overlayCanvas", document.body.clientWidth, window.innerHeight);
			setUpCanvas("#eventCanvas", document.body.clientWidth, document.getElementById("topSection").clientHeight);

			renderPoints(points);
		}

		// This adds the previously defined function as an event listener for 
		// the window resize event
		window.addEventListener("resize", renderOnResize);

		// This event listener finishes the resizing of the time axis when the 
		// mouse is unclicked. Needs to be async to call renderOnResize()
		document.body.addEventListener("mouseup", e => {
			if (resizing) {
				resizing = false;
				const ctx = overlayCanvas.getContext("2d");
				ctx.clearRect(0, 0, overlayCanvas.width, overlayCanvas.height);
				drawLine(ctx, e.clientX, 0, e.clientX, overlayCanvas.height, 2);

				const click = (mouseStart / window.innerWidth) * (pageEnd - pageStart) + pageStart;
				const unclick = (e.clientX / window.innerWidth) * (pageEnd - pageStart) + pageStart;

				if (Math.abs(mouseStart - e.clientX) > 20) {
					pageStart = e.clientX > mouseStart ? click : unclick;
					pageEnd = e.clientX > mouseStart ? unclick : click;
					renderOnResize();
				}
			}
		});

		// Adds a reset zoom event listener to the corresponding button
		document.querySelector("#resetZoom").addEventListener("click", () => {
			pageStart = 0;
			pageEnd = maxEnd;
			renderOnResize();
		});
        
		// Renders the horizontal axis at the top of the screen
		renderTopBar();
	})(); // End of async zone!
    
	// Whenever the add series button is clicked, the series that is currently
	// selected under the series selector drop down is then added to our list
	// of currently plotted series and then the graphs are refreshed.
	document.querySelector("#addSeriesButton").addEventListener("click", e => {
		e.stopPropagation();
		const canvas = document.createElement("canvas");
		canvas.setAttribute("width", document.body.clientWidth);
		canvas.setAttribute("height", 200);

		seriesToPlot.push({
			name: document.querySelector("#seriesSelector").value,
			canvas: canvas,
		});
		refresh();
	});
    

	// This section sets the width and height of the overlay canvas to be the 
	// full screen width and height
	const overlayCanvas = setUpCanvas("#overlayCanvas", window.innerWidth, window.innerHeight);

	// Adds an overlay redraw action to the event listener for mouse movement
	document.body.addEventListener("mousemove", e => {
		const ctx = overlayCanvas.getContext("2d");
		ctx.clearRect(0, 0, overlayCanvas.width, overlayCanvas.height);
		if (!resizing) {
			drawLine(ctx, e.clientX, 0, e.clientX, overlayCanvas.height, 2, "#000");
		} else {
			ctx.fillStyle = "#003cc7";
			ctx.fillRect(mouseStart, 0, e.clientX - mouseStart, overlayCanvas.height);
		}
	});

	// Starts the resizing process of the time axis when the mouse is clicked
	document.body.addEventListener("mousedown", e => {
		resizing = true;
		mouseStart = e.clientX;
	});

	// Stops the mouse up and down events from activating on any selector
	document.querySelectorAll("select").forEach(element => {
		element.addEventListener("mouseup", e => {
			e.stopPropagation();
		});
        
		element.addEventListener("mousedown", e => {
			e.stopPropagation();
		});
	});


	// Makes the body fullscreen so that the mouse event listeners activate
	// everywhere on the page
	document.body.style.position = "absolute";
	document.body.style.top = "0";
	document.body.style.bottom = "0";
	document.body.style.left = "0";
	document.body.style.right = "0";
});

/**
 * This function should be called whenever the state is updated.
 * Add stuff in here when new state or state-modification methods are created
 */
function refresh() {
	document.querySelector("#data").innerHTML = "";

	for (const series of seriesToPlot) {
		if (document.querySelector("#data").children.length !== seriesToPlot.length) {
			const div = document.createElement("div");
			div.setAttribute("data-series", series.name);
			div.setAttribute("class", "graphDiv");
			document.querySelector("#data").appendChild(div);
			div.appendChild(series.canvas);

			const closeButton = document.createElement("button");
			closeButton.innerHTML = "x";
			closeButton.setAttribute("class", "closeButton");
			closeButton.addEventListener("click", () => {
				seriesToPlot = seriesToPlot.filter(currentSeries => currentSeries.name !== series.name);
				refresh();
			});

			div.appendChild(closeButton);
		}
		
		graphDataOnCanvas(dataSeries[series.name], series.canvas);
	}
}

async function loadMatches() {
	const response = await fetch("/logs");
	if (!response.ok) {
		console.error("The response wasn't okay", response);
		return;
	}

	return (await response.text()).split("\\n").filter(name => name).sort();
}

/**
 * Loads the log messages from a specific log file. This also populates
 * the dataSeries variable with a bunch of names of data series.
 * @param {Number} match the number match to load
 * @returns a list of log messages in JSON
 */
async function loadMatch(match) {
	const response = await fetch(`/logs/${match}`);
	if (!response.ok) {
		console.error("The response wasn't okay", response);
		return;
	}

	const logMessages = (await response.text())
		.split("\n")
		.filter(value => Object.keys(value).length !== 0)
		.map(message => JSON.parse(message));

	let dataSeriesNames = [];
	for (const logMessage of logMessages.filter(message => message.type === "data")) {
		dataSeriesNames.push(logMessage.name);
	}
	dataSeriesNames = Array.from(new Set(dataSeriesNames));

	document.querySelector("#seriesSelector").innerHTML = "";
	for (const dataSeriesName of dataSeriesNames) {
		const option = document.createElement("option");
		option.setAttribute("value", dataSeriesName);
		document.querySelector("#seriesSelector").appendChild(option);
		option.innerHTML = dataSeriesName;
	}

	// Determine the maximum timestamp present in the logs to set
	// the time axis range for the page
	const timestamps = logMessages.map(message => message.time);

	maxEnd = Math.max(...timestamps, 5);
	// Add 5% padding on to the end
	pageEnd = maxEnd * 1.05;

	return logMessages;
}

/**
 * Parses a list of log messages and returns formatted spacetime events
 * @param {*} logs the log messages (in JSON form) to parse
 * @returns formatted spacetime events
 */
function getSpacetimeEvents(logs) {
	const inProgressEvents = {};
	for (const log of logs.filter(log => log.type === "event")) {
		if (inProgressEvents[log.id] === undefined) {
			inProgressEvents[log.id] = {
				message: log.message,
				id: log.id,
				parentID: log.parent,
				startTime: log.time,
				endTime: null,
				children: [],
			};
		} else {
			inProgressEvents[log.id].endTime = log.time;
		}
	}

	const spacetimeEvents = Object.values(inProgressEvents).filter(event => event.endTime !== null)
		.map(event => {
			if (event.parentID === -1) {
				return event;
			} else {
				inProgressEvents[event.parentID].children.push(event);
			}
		});

	return spacetimeEvents;
}

function getPointEvents(logs) {
	const inProgressEvents = {};
	for (const log of logs.filter(log => log.type === "event")) {
		if (inProgressEvents[log.id] === undefined) {
			inProgressEvents[log.id] = log;
		} else {
			inProgressEvents[log.id].endTime = log.time;
		}
	}

	const pointEvents = Object.values(inProgressEvents).filter(event => event.endTime === undefined);

	return pointEvents;
}

/**
 * Takes a list of spacetime events and sorts them into tracks
 * depending on whether or not they overlap
 * @param {*} spacetimeEvents 
 */
function sortIntoTracks(spacetimeEvents) {
	const sortedTracks = [];
	for (const event of spacetimeEvents) {
		let trackIndex = 0;
		while (trackIndex < sortedTracks.length) {
			const track = sortedTracks[trackIndex];
			if (!track.some(trackEvent => doEventsOverlap(event, trackEvent))) {
				track.push(event);
				break;
			}
			trackIndex++;
		}

		if (trackIndex >= sortedTracks.length) {
			sortedTracks.push([event]);
		} 
	}

	return sortedTracks;
}

/**
 * A function used when getting the height of certain spacetime events
 * @param {*} events the events to get the combined height of
 * @param {*} levels the levels those events are on
 * @param {*} currentLevel the current level being worked on
 * @returns the combined height of all of those events
 */
function getHeightOfEvents(events, levels, currentLevel) {
	const sortedTracks = sortIntoTracks(events);
	let height = 0;
	for (const track of sortedTracks) {
		const eventHeights = track.map(event => getHeightOfEvent(event, levels, currentLevel + height));
		const maxHeight = eventHeights.reduce((currentMax, height) => height > currentMax ? height : currentMax);
		height += maxHeight;
	}

	return height;
}

/** 
 * Gets the height of just one event and recurses back into the getHeightOfEvents
*/
function getHeightOfEvent(event, levels, currentLevel) {
	levels[event.id] = currentLevel;
	return 1 + getHeightOfEvents(event.children, levels, currentLevel + 1);
}

/**
 * A wrapper function that gets the levels that each spacetime event is located
 * @param {*} events a list of spacetime events that are being analyzed
 * @returns a list of levels that will contain the level of each spacetime event
 */
function getLevels(events) {
	const levels = {};
	getHeightOfEvents(events, levels, 0);
	return levels;
}

/**
 * Extracts the data from log files
 * @param {*} logs the log files to parse from
 * @returns a list of data series each containing points
 */
function getDataSeries(logs) {
	const dataSeries = {};
	for (const log of logs.filter(log => log.type === "data")) {
		if (dataSeries[log.name] === undefined) {
			dataSeries[log.name] = { points: [] };
		}

		dataSeries[log.name].points.push({ time: log.time, value: log.value });
	}

	return dataSeries;
}

/**
 * Allows a data series to be graphed on a certain canvas
 * @param {*} dataSeries the series to plot
 * @param {*} canvas the canvas to plot on
 */
function graphDataOnCanvas(dataSeries, canvas) {
	const ctx = canvas.getContext("2d");
	ctx.clearRect(0, 0, canvas.width, canvas.height);
	const maxValue = Math.max(...dataSeries.points.map(point => point.value));
	const minValue = Math.min(...dataSeries.points.map(point => point.value));

	function convertToPixels(point) {
		const x = (point.time - pageStart) / (pageEnd - pageStart) * canvas.width;
		const y = (maxValue - point.value)  / (maxValue - minValue) * (canvas.height - verticalPadding * 2) + verticalPadding;
		return [x, y];
	}

	for (let i = 0; i < dataSeries.points.length; i++) {
		const [x, y] = convertToPixels(dataSeries.points[i]);
		drawCircle(ctx, x, y, 5);

		if (i > 0) {
			const [x1, y1] = convertToPixels(dataSeries.points[i - 1]);
			const [x2, y2] = convertToPixels(dataSeries.points[i]);
			drawLine(ctx, x1, y1, x2, y2);
		}
	}

	drawLine(ctx, 5, verticalPadding, 5, canvas.height - verticalPadding);
	for (let i = 0; i < 5; i++) {
		const paddingHeight = (canvas.height - verticalPadding * 2);
		const height = i * paddingHeight / 4 + verticalPadding;
		const heightInUnits = (paddingHeight - height) / paddingHeight * (maxValue - minValue) + minValue;
		drawLine(ctx, 5, height, 20, height);
		drawText(ctx, Math.round(heightInUnits * 100) / 100, {x: 27, y: height + 5});
		drawLine(ctx, 60, height, canvas.width, height, 1, "#aaa");
	}
}

function setUpCanvas(query, width, height) {
	const canvas = document.querySelector(query);
	canvas.setAttribute("width", width);
	canvas.setAttribute("height", height);
	return canvas;
}

/**
 * Tells you whether two spacetime events overlap or not
 * @param {*} event1 
 * @param {*} event2 
 */
function doEventsOverlap(event1, event2) {
	return event1.startTime < event2.endTime && event1.endTime > event2.startTime;
}

/**
 * Renders the horizontal axis at the top of the screen
 */
function renderTopBar() {
	const canvas = setUpCanvas("#topBarCanvas", document.body.clientWidth, 50);
	const ctx = canvas.getContext("2d");
	drawLine(ctx, 0, 0, canvas.width, 0, 8);
	const scale = Math.min(8, Math.round( Math.log(10 / (pageEnd - pageStart))));
	for (let i = 0; i < 20; i++) {
		const horizontalPos = i * canvas.width / 19;
		const horizontalPosInUnits = horizontalPos / canvas.width * (pageEnd - pageStart) + pageStart;
		drawLine(ctx, horizontalPos, 3, horizontalPos, 12);
		drawText(ctx, horizontalPosInUnits.toFixed(Math.max(scale, 1)), {x: horizontalPos - 12, y: 28});
	}
}

function getCurrentMatch() {
	return document.querySelector("#matchSelect").value;
}

function getMostParentID(event, logs) {
	const parentID = event.parent ?? -1;
	if (parentID === -1) return event.id;
	
	logs.forEach(log => {
		if (log.id === parentID) return getMostParentID({name: log.message, id: log.id, parentID: log.parent}, logs);
	});
}

/**
 * Draws a circle on a canvas
 * @param {*} context the context of the canvas to draw on
 * @param {Number} x the x-coordinate of the center
 * @param {Number} y the y-coordinate of the center
 * @param {Number} radius the radius of the circle
 * @param {String} color the fill color of the circle
 */
function drawCircle(context, x, y, radius, color = "black") {
	context.beginPath();
	context.arc(x, y, radius, 0, 2 * Math.PI, false);
	context.fillStyle = color;
	context.fill();
}

/**
 * Draws a line on a canvas
 * @param {*} context the context of the canvas to draw on
 * @param {Number} x1 the x-coordinate of the starting point
 * @param {Number} y1 the y-coordinate of the starting point
 * @param {Number} x2 the x-coordinate of the ending point
 * @param {Number} y2 the y-coordinate of the ending point
 * @param {Number} thickness how thick to make the line (pixels)
 * @param {String} color the color of the line
 */
function drawLine(context, x1, y1, x2, y2, thickness = 2, color = "black") {
	context.beginPath();
	context.moveTo(x1, y1);
	context.lineTo(x2, y2);
	context.lineWidth = thickness;
	context.strokeStyle = color;
	context.stroke();
}

/**
 * Draws some text on a canvas
 * @param {*} context the context of the canvas to draw on
 * @param {String} text the text to draw
 * @param {*} origin the origin point of the text being drawn
 * @param {String} color the color of the text
 * @param {Number} size the font size
 * @param {String} font the font family
 */
function drawText(context, text, origin, color = "black", size = 14, font = "Arial") {
	context.font = size + "px " + font;
	context.fillStyle = color;
	context.fillText(text, origin.x, origin.y);
}