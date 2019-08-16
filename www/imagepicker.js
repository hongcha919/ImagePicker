cordova.define("com.haoqi.imagepicker.ImagePicker", function(require, exports, module) {
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


ImagePicker.prototype.upload = function(success, fail, options) {
	if (!options) {
		options = {};
	}

	this.validateOutputType(options);

	//上传资源类型 1 录音 2 录制 3 选择图片 4选择视频  默认上传图片
    var type = options.type ? options.type : 3;

	//初始化公共参数
	var params = {
		//1 录音 2 录制 3 选择图片 4选择视频
		type: type,
		//服务端地址(测服，线上服地址以后可能会改)
		serverUrl: options.serverUrl ? options.serverUrl : "",
		//腾讯云上传appid
		appid: options.appid ? options.appid : "",
		//腾讯云存储桶地址
		region: options.region ? options.region : "ap-guangzhou",
		//用户标识 用于请求上传签名和媒体对象(测试时可用测试接口获取进行测试）
		ticket:options.ticket ? options.ticket : "",
		//机构id用于请求上传签名和媒体对象（测试时可写死1）
		orgId: options.orgId ? options.orgId : 1,
		//test 测试 release 线上
		environment: options.environment ? options.environment : "test",
		
		//选择视图的颜色值设置 
		//底部按钮背景色
		oKButtonTitleColorNormal: options.oKButtonTitleColorNormal ? options.oKButtonTitleColorNormal : "#1aad19",
		oKButtonTitleColorDisabled: options.oKButtonTitleColorDisabled ? options.oKButtonTitleColorDisabled : "#175216",
		//首页导航栏背景色
		naviBgColor: options.naviBgColor ? options.naviBgColor : "#393A3F",
		naviTitleColor: options.naviTitleColor ? options.naviTitleColor : "#ffffff",
		barItemTextColor: options.barItemTextColor ? options.barItemTextColor : "#ffffff",
		//预览视图导航栏背景色
		previewNaviBgColor: options.previewNaviBgColor ? options.previewNaviBgColor : "#222222e6",
		//底部toolbar背景色及标题颜色
		toolbarBgColor: options.toolbarBgColor ? options.toolbarBgColor : "#393A3F",
		toolbarTitleColorNormal: options.toolbarTitleColorNormal ? options.toolbarTitleColorNormal : "#ffffff",
		toolbarTitleColorDisabled: options.toolbarTitleColorDisabled ? options.toolbarTitleColorDisabled : "#5c666a",
		//编辑视图导航栏背景色及按钮标题颜色
		editNaviBgColor: options.editNaviBgColor ? options.editNaviBgColor : "#222222e6",
		editOKButtonTitleColorNormal: options.editOKButtonTitleColorNormal ? options.editOKButtonTitleColorNormal : "#1aad19",
		editCancelButtonTitleColorNormal: options.editCancelButtonTitleColorNormal ? options.editCancelButtonTitleColorNormal : "#cccccc",
		//编辑视图底部工具栏
		editToolbarBgColor: options.editToolbarBgColor ? options.editToolbarBgColor : "#393A3F",
		editToolbarTitleColorNormal: options.editToolbarTitleColorNormal ? options.editToolbarTitleColorNormal : "#ffffff",
		editToolbarTitleColorDisabled: options.editToolbarTitleColorDisabled ? options.editToolbarTitleColorDisabled : "#5c666a",
	};

    //处理其他参数
	if(type == 1){ //语音上传
		//允许录制最大长度，默认为60s
		params.duration = options.duration ? options.duration : 60;
	} else if (type == 2){ //录制图片/视频上传
		//拍摄图片 只能上传一张图片
		params.maximumImagesCount = 1;
		//最小缩放比例 默认1
		params.customMinZoomScale = options.customMinZoomScale ? options.customMinZoomScale : 1.0;
		params.width = options.width ? options.width : 0;
		params.height = options.height ? options.height : 0;
		//图片质量
		params.quality = options.quality ? options.quality : 100;
		//图片裁剪形状(1圆形;2正方形;3矩形) 默认正方形2
		params.cutType = (options.cutType || options.cutType==0) ? options.cutType : 2;
		//图片裁剪宽度
		params.cutWidth = options.cutWidth ? options.cutWidth : 0;
		//图片裁剪高度
		params.cutHeigth = options.cutHeigth ? options.cutHeigth : 0;
		//输出格式：0.文件绝对路径 1.BASE64_STRING
		params.outputType = options.outputType ? options.outputType : this.OutputType.FILE_URI;


		//允许录制最大长度，默认为60s
		params.duration = options.duration ? options.duration : 60;
	} else if (type == 4){ //选择视频上传
		//允许上传视频最大长度，默认为60s,选择上传的视频长度大于最大长度，则强制裁剪
		params.duration = options.duration ? options.duration : 60;
		//最多选择个数 默认1
		params.maximumVideosCount = options.maximumVideosCount ? options.maximumVideosCount : 1;
	} else { //选择图片上传
		//最多选择个数 默认15
		params.maximumImagesCount = options.maximumImagesCount ? options.maximumImagesCount : 15;
		//最小缩放比例 默认1
		params.customMinZoomScale = options.customMinZoomScale ? options.customMinZoomScale : 1.0;
		params.width = options.width ? options.width : 0;
		params.height = options.height ? options.height : 0;
		//图片质量
		params.quality = options.quality ? options.quality : 100;
		//图片裁剪形状(1圆形;2正方形;3矩形) 默认正方形
		params.cutType = (options.cutType || options.cutType==0) ? options.cutType : 2;
		//图片裁剪宽度
		params.cutWidth = options.cutWidth ? options.cutWidth : 0;
		//图片裁剪高度
		params.cutHeigth = options.cutHeigth ? options.cutHeigth : 0;
		//输出格式：0.文件绝对路径 1.BASE64_STRING
		params.outputType = options.outputType ? options.outputType : this.OutputType.FILE_URI;
	}
	

	return cordova.exec(success, fail, "ImagePicker", "upload", [params]);
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

		//1 录音 2 录制 3 选择图片 4选择视频
		type: 3,
		//服务端地址(测服，线上服地址以后可能会改)
		serverUrl: options.serverUrl ? options.serverUrl : "",
		//腾讯云上传appid
		appid: options.appid ? options.appid : "",
		//腾讯云存储桶地址
		region: options.region ? options.region : "ap-guangzhou",
		//用户标识 用于请求上传签名和媒体对象(测试时可用测试接口获取进行测试）
		ticket:options.ticket ? options.ticket : "",
		//机构id用于请求上传签名和媒体对象（测试时可写死1）
		orgId: options.orgId ? options.orgId : 1,
		//test 测试 release 线上
		environment: options.environment ? options.environment : "test",

		maximumImagesCount: options.maximumImagesCount ? options.maximumImagesCount : 15,
		customMinZoomScale: options.customMinZoomScale ? options.customMinZoomScale : 1.0,
		width: options.width ? options.width : 0,
		height: options.height ? options.height : 0,
		quality: options.quality ? options.quality : 100,

		cutType: (options.cutType || options.cutType==0) ? options.cutType : 2,
		cutWidth: options.cutWidth ? options.cutWidth : 0,
		cutHeigth: options.cutHeigth ? options.cutHeigth : 0,

		outputType: options.outputType ? options.outputType : this.OutputType.FILE_URI,

		oKButtonTitleColorNormal: options.oKButtonTitleColorNormal ? options.oKButtonTitleColorNormal : "#1aad19",
		oKButtonTitleColorDisabled: options.oKButtonTitleColorDisabled ? options.oKButtonTitleColorDisabled : "#175216",
		naviBgColor: options.naviBgColor ? options.naviBgColor : "#393A3F",
		naviTitleColor: options.naviTitleColor ? options.naviTitleColor : "#ffffff",
		barItemTextColor: options.barItemTextColor ? options.barItemTextColor : "#ffffff",
		previewNaviBgColor: options.previewNaviBgColor ? options.previewNaviBgColor : "#222222e6",
		toolbarBgColor: options.toolbarBgColor ? options.toolbarBgColor : "#393A3F",
		toolbarTitleColorNormal: options.toolbarTitleColorNormal ? options.toolbarTitleColorNormal : "#ffffff",
		toolbarTitleColorDisabled: options.toolbarTitleColorDisabled ? options.toolbarTitleColorDisabled : "#5c666a",
		editNaviBgColor: options.editNaviBgColor ? options.editNaviBgColor : "#222222e6",
		editOKButtonTitleColorNormal: options.editOKButtonTitleColorNormal ? options.editOKButtonTitleColorNormal : "#1aad19",
		editCancelButtonTitleColorNormal: options.editCancelButtonTitleColorNormal ? options.editCancelButtonTitleColorNormal : "#cccccc",
		editToolbarBgColor: options.editToolbarBgColor ? options.editToolbarBgColor : "#393A3F",
		editToolbarTitleColorNormal: options.editToolbarTitleColorNormal ? options.editToolbarTitleColorNormal : "#ffffff",
		editToolbarTitleColorDisabled: options.editToolbarTitleColorDisabled ? options.editToolbarTitleColorDisabled : "#5c666a",
	};

	return cordova.exec(success, fail, "ImagePicker", "getPictures", [params]);
};

ImagePicker.prototype.getVideos = function(success, fail, options) {
	if (!options) {
		options = {};
	}

	this.validateOutputType(options);

	var params = {

		//1 录音 2 录制 3 选择图片 4选择视频
		type: 4,
		//服务端地址(测服，线上服地址以后可能会改)
		serverUrl: options.serverUrl ? options.serverUrl : "",
		//腾讯云上传appid
		appid: options.appid ? options.appid : "",
		//腾讯云存储桶地址
		region: options.region ? options.region : "ap-guangzhou",
		//用户标识 用于请求上传签名和媒体对象(测试时可用测试接口获取进行测试）
		ticket:options.ticket ? options.ticket : "",
		//机构id用于请求上传签名和媒体对象（测试时可写死1）
		orgId: options.orgId ? options.orgId : 1,
		//test 测试 release 线上
		environment: options.environment ? options.environment : "test",

		maximumImagesCount: options.maximumImagesCount ? options.maximumImagesCount : 15,
		customMinZoomScale: options.customMinZoomScale ? options.customMinZoomScale : 1.0,
		width: options.width ? options.width : 0,
		height: options.height ? options.height : 0,
		quality: options.quality ? options.quality : 100,

		cutType: (options.cutType || options.cutType==0) ? options.cutType : 2,
		cutWidth: options.cutWidth ? options.cutWidth : 0,
		cutHeigth: options.cutHeigth ? options.cutHeigth : 0,

		outputType: options.outputType ? options.outputType : this.OutputType.FILE_URI,

		oKButtonTitleColorNormal: options.oKButtonTitleColorNormal ? options.oKButtonTitleColorNormal : "#1aad19",
		oKButtonTitleColorDisabled: options.oKButtonTitleColorDisabled ? options.oKButtonTitleColorDisabled : "#175216",
		naviBgColor: options.naviBgColor ? options.naviBgColor : "#393A3F",
		naviTitleColor: options.naviTitleColor ? options.naviTitleColor : "#ffffff",
		barItemTextColor: options.barItemTextColor ? options.barItemTextColor : "#ffffff",
		previewNaviBgColor: options.previewNaviBgColor ? options.previewNaviBgColor : "#222222e6",
		toolbarBgColor: options.toolbarBgColor ? options.toolbarBgColor : "#393A3F",
		toolbarTitleColorNormal: options.toolbarTitleColorNormal ? options.toolbarTitleColorNormal : "#ffffff",
		toolbarTitleColorDisabled: options.toolbarTitleColorDisabled ? options.toolbarTitleColorDisabled : "#5c666a",
		editNaviBgColor: options.editNaviBgColor ? options.editNaviBgColor : "#222222e6",
		editOKButtonTitleColorNormal: options.editOKButtonTitleColorNormal ? options.editOKButtonTitleColorNormal : "#1aad19",
		editCancelButtonTitleColorNormal: options.editCancelButtonTitleColorNormal ? options.editCancelButtonTitleColorNormal : "#cccccc",
		editToolbarBgColor: options.editToolbarBgColor ? options.editToolbarBgColor : "#393A3F",
		editToolbarTitleColorNormal: options.editToolbarTitleColorNormal ? options.editToolbarTitleColorNormal : "#ffffff",
		editToolbarTitleColorDisabled: options.editToolbarTitleColorDisabled ? options.editToolbarTitleColorDisabled : "#5c666a",
	};

	return cordova.exec(success, fail, "ImagePicker", "getVideos", [params]);
};

ImagePicker.prototype.getAudio = function(success, fail, options) {
	if (!options) {
		options = {};
	}

	this.validateOutputType(options);

	var params = {

		//1 录音 2 录制 3 选择图片 4选择视频
		type: 1,
		//服务端地址(测服，线上服地址以后可能会改)
		serverUrl: options.serverUrl ? options.serverUrl : "",
		//腾讯云上传appid
		appid: options.appid ? options.appid : "",
		//腾讯云存储桶地址
		region: options.region ? options.region : "ap-guangzhou",
		//用户标识 用于请求上传签名和媒体对象(测试时可用测试接口获取进行测试）
		ticket:options.ticket ? options.ticket : "",
		//机构id用于请求上传签名和媒体对象（测试时可写死1）
		orgId: options.orgId ? options.orgId : 1,
		//test 测试 release 线上
		environment: options.environment ? options.environment : "test",

		maximumImagesCount: options.maximumImagesCount ? options.maximumImagesCount : 15,
		customMinZoomScale: options.customMinZoomScale ? options.customMinZoomScale : 1.0,
		width: options.width ? options.width : 0,
		height: options.height ? options.height : 0,
		quality: options.quality ? options.quality : 100,

		cutType: (options.cutType || options.cutType==0) ? options.cutType : 2,
		cutWidth: options.cutWidth ? options.cutWidth : 0,
		cutHeigth: options.cutHeigth ? options.cutHeigth : 0,

		outputType: options.outputType ? options.outputType : this.OutputType.FILE_URI,

		oKButtonTitleColorNormal: options.oKButtonTitleColorNormal ? options.oKButtonTitleColorNormal : "#1aad19",
		oKButtonTitleColorDisabled: options.oKButtonTitleColorDisabled ? options.oKButtonTitleColorDisabled : "#175216",
		naviBgColor: options.naviBgColor ? options.naviBgColor : "#393A3F",
		naviTitleColor: options.naviTitleColor ? options.naviTitleColor : "#ffffff",
		barItemTextColor: options.barItemTextColor ? options.barItemTextColor : "#ffffff",
		previewNaviBgColor: options.previewNaviBgColor ? options.previewNaviBgColor : "#222222e6",
		toolbarBgColor: options.toolbarBgColor ? options.toolbarBgColor : "#393A3F",
		toolbarTitleColorNormal: options.toolbarTitleColorNormal ? options.toolbarTitleColorNormal : "#ffffff",
		toolbarTitleColorDisabled: options.toolbarTitleColorDisabled ? options.toolbarTitleColorDisabled : "#5c666a",
		editNaviBgColor: options.editNaviBgColor ? options.editNaviBgColor : "#222222e6",
		editOKButtonTitleColorNormal: options.editOKButtonTitleColorNormal ? options.editOKButtonTitleColorNormal : "#1aad19",
		editCancelButtonTitleColorNormal: options.editCancelButtonTitleColorNormal ? options.editCancelButtonTitleColorNormal : "#cccccc",
		editToolbarBgColor: options.editToolbarBgColor ? options.editToolbarBgColor : "#393A3F",
		editToolbarTitleColorNormal: options.editToolbarTitleColorNormal ? options.editToolbarTitleColorNormal : "#ffffff",
		editToolbarTitleColorDisabled: options.editToolbarTitleColorDisabled ? options.editToolbarTitleColorDisabled : "#5c666a",
	};

	return cordova.exec(success, fail, "ImagePicker", "getAudio", [params]);
};

ImagePicker.prototype.shootPhoto_Video = function(success, fail, options) {
	if (!options) {
		options = {};
	}

	this.validateOutputType(options);

	var params = {

		//1 录音 2 录制 3 选择图片 4选择视频
		type: 2,
		//服务端地址(测服，线上服地址以后可能会改)
		serverUrl: options.serverUrl ? options.serverUrl : "",
		//腾讯云上传appid
		appid: options.appid ? options.appid : "",
		//腾讯云存储桶地址
		region: options.region ? options.region : "ap-guangzhou",
		//用户标识 用于请求上传签名和媒体对象(测试时可用测试接口获取进行测试）
		ticket:options.ticket ? options.ticket : "",
		//机构id用于请求上传签名和媒体对象（测试时可写死1）
		orgId: options.orgId ? options.orgId : 1,
		//test 测试 release 线上
		environment: options.environment ? options.environment : "test",
		
		maximumImagesCount: options.maximumImagesCount ? options.maximumImagesCount : 15,
		customMinZoomScale: options.customMinZoomScale ? options.customMinZoomScale : 1.0,
		width: options.width ? options.width : 0,
		height: options.height ? options.height : 0,
		quality: options.quality ? options.quality : 100,

		cutType: (options.cutType || options.cutType==0) ? options.cutType : 2,
		cutWidth: options.cutWidth ? options.cutWidth : 0,
		cutHeigth: options.cutHeigth ? options.cutHeigth : 0,

		outputType: options.outputType ? options.outputType : this.OutputType.FILE_URI,

		oKButtonTitleColorNormal: options.oKButtonTitleColorNormal ? options.oKButtonTitleColorNormal : "#1aad19",
		oKButtonTitleColorDisabled: options.oKButtonTitleColorDisabled ? options.oKButtonTitleColorDisabled : "#175216",
		naviBgColor: options.naviBgColor ? options.naviBgColor : "#393A3F",
		naviTitleColor: options.naviTitleColor ? options.naviTitleColor : "#ffffff",
		barItemTextColor: options.barItemTextColor ? options.barItemTextColor : "#ffffff",
		previewNaviBgColor: options.previewNaviBgColor ? options.previewNaviBgColor : "#222222e6",
		toolbarBgColor: options.toolbarBgColor ? options.toolbarBgColor : "#393A3F",
		toolbarTitleColorNormal: options.toolbarTitleColorNormal ? options.toolbarTitleColorNormal : "#ffffff",
		toolbarTitleColorDisabled: options.toolbarTitleColorDisabled ? options.toolbarTitleColorDisabled : "#5c666a",
		editNaviBgColor: options.editNaviBgColor ? options.editNaviBgColor : "#222222e6",
		editOKButtonTitleColorNormal: options.editOKButtonTitleColorNormal ? options.editOKButtonTitleColorNormal : "#1aad19",
		editCancelButtonTitleColorNormal: options.editCancelButtonTitleColorNormal ? options.editCancelButtonTitleColorNormal : "#cccccc",
		editToolbarBgColor: options.editToolbarBgColor ? options.editToolbarBgColor : "#393A3F",
		editToolbarTitleColorNormal: options.editToolbarTitleColorNormal ? options.editToolbarTitleColorNormal : "#ffffff",
		editToolbarTitleColorDisabled: options.editToolbarTitleColorDisabled ? options.editToolbarTitleColorDisabled : "#5c666a",
	};

	return cordova.exec(success, fail, "ImagePicker", "shootPhoto_Video", [params]);
};

window.imagePicker = new ImagePicker();

});
