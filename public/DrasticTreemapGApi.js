var drasticdata = {};

// Class constructor.
drasticdata.DrasticTreemap = function(container) {
	this.containerElement = container;
}

// Main drawing logic.
drasticdata.DrasticTreemap.prototype.draw = function(data, options) {
	// Check options and calculate defaults if necessary:
	var stringCols = new Array();
	var numberCols = new Array();
	for (var i=0; i < data.getNumberOfColumns(); i++) {
		if (data.getColumnType(i) == "string") stringCols.push(data.getColumnLabel(i));
		if (data.getColumnType(i) == "number") numberCols.push(data.getColumnLabel(i));
	}
	if (stringCols.length == 0 || numberCols.length == 0) return;
	
	var groupbycol = (options && options.groupbycol && this.checkCol(data, options.groupbycol)) ? options.groupbycol : 
					(stringCols[1] ? stringCols[1] : stringCols[0]);
	var labelcol = (options && options.labelcol && this.checkCol(data, options.labelcol)) ? options.labelcol : stringCols[0];
	
	var var1 = (options && options.variables && options.variables[0] && this.checkCol(data, options.variables[0])) ? options.variables[0] : numberCols[0];
	var var2 = (options && options.variables && options.variables[1] && this.checkCol(data, options.variables[1])) ? options.variables[1] : (numberCols[1] ? numberCols[1] : "");
	var var3 = (options && options.variables && options.variables[2] && this.checkCol(data, options.variables[2])) ? options.variables[2] : (numberCols[2] ? numberCols[2] : "");
	//var var4 = (options && options.variables && options.variables[3] && this.checkCol(data, options.variables[3])) ? options.variables[2] : (numberCols[3] ? numberCols[3] : "");

	var flashvars = {};
	flashvars.groupbycol = encodeURIComponent(groupbycol);
	flashvars.labelcol = encodeURIComponent(labelcol);
	flashvars.var1 = encodeURIComponent(var1);
	flashvars.var2 = encodeURIComponent(var2);
	flashvars.var3 = encodeURIComponent(var3);
	//flashvars.var4 = encodeURIComponent(var4);
	flashvars.data = encodeURIComponent(data.toJSON());
	var params = { menu: "false" };
		
	// call swf:
	var thetreemap = swfobject.embedSWF("DrasticTreemapGApi09.swf", this.containerElement.id, 
			parseInt(this.containerElement.style.width), 
			parseInt(this.containerElement.style.height), 
			"9.0.0", "expressInstall.swf", flashvars, params);
}

drasticdata.DrasticTreemap.prototype.checkCol = function(data, colname) {
	for (var i=0; i < data.getNumberOfColumns(); i++)
		if (colname == data.getColumnLabel(i)) return(true);
	return(false);
}