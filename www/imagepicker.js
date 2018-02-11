/*global cordova,window,console*/
/**
 * An Image Picker plugin for Cordova
 *
 * Developed by Wymsee for Sync OnSet
 */

var ImagePicker = function() {

};

ImagePicker.prototype.OutputType = {
	FILE_URI: 0,
	BASE64_STRING: 1
};

ImagePicker.prototype.validateOutputType = function(options){
	var outputType = options.outputType;
	if(outputType){
		if(outputType !== this.OutputType.FILE_URI && outputType !== this.OutputType.BASE64_STRING){
			console.log('Invalid output type option entered. Defaulting to FILE_URI. Please use window.imagePicker.OutputType.FILE_URI or window.imagePicker.OutputType.BASE64_STRING');
			options.outputType = this.OutputType.FILE_URI;
		}
	}
};

ImagePicker.prototype.hasReadPermission = function(callback) {
  return cordova.exec(callback, null, "ImagePicker", "hasReadPermission", []);
};

ImagePicker.prototype.requestReadPermission = function(callback) {
  return cordova.exec(callback, null, "ImagePicker", "requestReadPermission", []);
};

/*
*	success - success callback
*	fail - error callback
*	options
*		.maximumImagesCount - max images to be selected, defaults to 15. If this is set to 1,
*		                      upon selection of a single image, the plugin will return it.
*		.width - width to resize image to (if one of height/width is 0, will resize to fit the
*		         other while keeping aspect ratio, if both height and width are 0, the full size
*		         image will be returned)
*		.height - height to resize image to
*		.quality - quality of resized image, defaults to 100
*       .outputType - type of output returned. defaults to file URIs.
*					  Please see ImagePicker.OutputType for available values.
*/
ImagePicker.prototype.getPictures = function(success, fail, options) {
	if (!options) {
		options = {};
	}

	this.validateOutputType(options);

	var params = {
		maximumImagesCount: options.maximumImagesCount ? options.maximumImagesCount : 15,
		width: options.width ? options.width : 0,
		height: options.height ? options.height : 0,
		quality: options.quality ? options.quality : 100,

		cutType: (options.cutType || options.cutType==0) ? options.cutType : 3,
		cutWidth: options.cutWidth ? options.cutWidth : 0,
		cutHeigth: options.cutHeigth ? options.cutHeigth : 0,

		outputType: options.outputType ? options.outputType : this.OutputType.FILE_URI,

		oKButtonTitleColorNormal: options.oKButtonTitleColorNormal ? options.oKButtonTitleColorNormal : "#1aad19",
		oKButtonTitleColorDisabled: options.oKButtonTitleColorDisabled ? options.oKButtonTitleColorDisabled : "#175216",
		naviBgColor: options.naviBgColor ? options.naviBgColor : "#222222e6",
		naviTitleColor: options.naviTitleColor ? options.naviTitleColor : "#ffffff",
		barItemTextColor: options.barItemTextColor ? options.barItemTextColor : "#ffffff",
		previewNaviBgColor: options.previewNaviBgColor ? options.previewNaviBgColor : "#222222e6",
		toolbarBgColor: options.toolbarBgColor ? options.toolbarBgColor : "#1a1a1ae6",
		toolbarTitleColorNormal: options.toolbarTitleColorNormal ? options.toolbarTitleColorNormal : "#ffffff",
		toolbarTitleColorDisabled: options.toolbarTitleColorDisabled ? options.toolbarTitleColorDisabled : "#5c666a",
		editNaviBgColor: options.editNaviBgColor ? options.editNaviBgColor : "#222222e6",
		editOKButtonTitleColorNormal: options.editOKButtonTitleColorNormal ? options.editOKButtonTitleColorNormal : "#1aad19",
		editCancelButtonTitleColorNormal: options.editCancelButtonTitleColorNormal ? options.editCancelButtonTitleColorNormal : "#cccccc",
		editToolbarBgColor: options.editToolbarBgColor ? options.editToolbarBgColor : "#1a1a1ae6",
	};

	return cordova.exec(success, fail, "ImagePicker", "getPictures", [params]);
};

window.imagePicker = new ImagePicker();
