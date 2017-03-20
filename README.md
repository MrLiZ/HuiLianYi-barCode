# cordova-plugin-barcode 二维码扫描Cordova插件

This plugin implements barcode scanner on Cordova 4.0

## Supported Cordova Platforms

* Android 4.0.0 or above
* iOS 7.0.0 or above

## Usage
cordova plugin add https://github.com/MrLiZ/HuiLianYi-barCode.git

## JS 
``` js
com.jieweifu.plugins.barcode.startScan({
        message:{
                title:'扫码上方描述',
                tipScan:'扫码下方描述',
                tipInput:'输入单号提示',
                tipLoading:'调接口的过程中的提示',
                tipNetworkError:'网络错误时的提示',
                tipOffline:'没有打开web时的提示',
                openButton:'我已打开按钮文字',
                footerFirst:'底部提示第一行,可空',
                footerSecond:'底部提示第二行,可空'
        },
        operationType:'REVIEW',
        requests:[
                {
                    url:'www.huilianyi.com',
                    method:'POST',
                    headers:{
                        Authorization:'Bearer xxxxx',
                        Content-Type:'xxxx'
                    },

	            config: {
			timeout: 10000 (单位是毫秒)
		    },

                    data:{
                        code:'xxxx-xxxx',
                        operate:'xxxx'
                    }
                },
                ...
        ]

    },function(success){
        alert(JSON.stringify(success));
    }, function(error){
        alert(JSON.stringify(error));   
    });
```





