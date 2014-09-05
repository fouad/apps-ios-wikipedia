//  Created by Monte Hurd on 12/28/13.
//  Used by methods in "UIWebView+ElementLocation.h" category.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

function stringEndsWith(str, suffix) {
    return str.indexOf(suffix, str.length - suffix.length) !== -1;
}

function getZoomLevel() {
    // From: http://stackoverflow.com/a/5078596/135557
    var deviceWidth = (Math.abs(window.orientation) == 90) ? screen.height : screen.width;
    var zoom = deviceWidth / window.innerWidth;
    return zoom;
}

exports.getImageWithSrc = function(src) {
    var images = document.getElementsByTagName('IMG');
    for (var i = 0; i < images.length; ++i) {
        if (stringEndsWith(images[i].src, src)){
            return images[i];
        }
    }
    return null;
}

exports.getElementRect = function(element) {
    var rect = element.getBoundingClientRect();
    var zoom = getZoomLevel();
    var zoomedRect = new Object();
    zoomedRect['top'] = (rect.top + window.scrollY) * zoom;
    zoomedRect['left'] = (rect.left + window.scrollX) * zoom;
    zoomedRect['width'] = rect.width * zoom;
    zoomedRect['height'] = rect.height * zoom;
    return zoomedRect;
}

exports.getElementRectAsJson = function(element) {
    return JSON.stringify(this.getElementRect(element));
}

exports.getIndexOfFirstOnScreenElementWithTopGreaterThanY = function(elementPrefix, elementCount, y){
    for (var i = 0; i < elementCount; ++i) {
        var div = document.getElementById(elementPrefix + i);
        if(div == null) continue;
	var rect = this.getElementRect(div);
        if( (rect['top'] >= 0) || ((rect['top'] + rect['height']) >= 0)) return i;
    }
    return -1;
}
