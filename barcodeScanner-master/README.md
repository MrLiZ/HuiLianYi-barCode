# cordova-plugin-barcode 二维码扫描Cordova插件

This plugin implements barcode scanner on Cordova 4.0

## Supported Cordova Platforms

* Android 4.0.0 or above
* iOS 7.0.0 or above

![二维码图片](https://github.com/engine9012/barcodeScanner/blob/master/IMG_0650.PNG)

## Usage

cordova plugin add https://github.com/engine9012/barcodeScanner.git

## JS 
``` js
com.jieweifu.plugins.barcode.startScan(function(success){
    alert(JSON.stringify(success));
}, function(error){
    alert(JSON.stringify(error));
});
```
