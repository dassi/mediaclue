/**************************************************************************************************
	* Zamantou JavascriptMicroAPI 1.2
	* Releases <http://zanmantou.voodoon.com>
	* Copyright 2007 by Andi Dittrich <andi.dittrich@voodoon.com>
	* Terms of Use avaible under : "http://zanmantou.voodoon.com"
	* ALL RIGHTS RESERVED

	* This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
	* without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
**************************************************************************************************/

/* Universal Callback */
function ZanmantouCallback(id, args){
	for (var i = 0;i<ZanmantouInstance.length;i++){
		if (ZanmantouInstance[i][0] == id){
			ZanmantouInstance[i][1].callback(args);
		}
	}
}
/* Event Callback */
function ZanmantouEventCallback(id, args){
	for (var i = 0;i<ZanmantouInstance.length;i++){
		if (ZanmantouInstance[i][0] == id){
			ZanmantouInstance[i][1].eventCallback(args);
		}
	}
}

/* Alle erzeugten Zanamntou Instanzen */
var ZanmantouInstance = new Array();

/* konstruktor */
function Zanmantou(id){
	this.zanmantou = document.getElementById(id);
	this.id = id;
	this.isRegistered = false;
	this.callbackArgs = "";
	this.onChangeEvent = null;
	ZanmantouInstance.push(new Array(id, this));
}

/* callback */
Zanmantou.prototype.callback = function(args){
	this.callbackArgs = args + "";
}

/* event callback */
Zanmantou.prototype.eventCallback = function(args){
	// event verarbeiten
	// wenn es einen trackchange gibt
	if (args == 'change'){
		if (this.onChangeEvent != null){
			this.onChangeEvent.actionPerformed();
		}
	}
}

/* event registrieren */
Zanmantou.prototype.registerEvent = function(type, obj){
	if (type == 'onChange'){
		this.onChangeEvent = obj;
	}
}

Zanmantou.prototype.register = function(){
	if (!this.isRegistered){
		this.isRegistered = true;
		this.zanmantou.JMAPI_init(this.id);
	}
}

/* start */
Zanmantou.prototype.start = function(position){
	this.zanmantou.JMAPI_start(position);
}

/* stop */
Zanmantou.prototype.stop = function(){
	this.zanmantou.JMAPI_stop();
}

/* halt */
Zanmantou.prototype.halt = function(){
	this.zanmantou.JMAPI_halt();
}

/* next */
Zanmantou.prototype.next = function(){
	this.zanmantou.JMAPI_next();
}

/* last */
Zanmantou.prototype.last = function(){
	this.zanmantou.JMAPI_prev();
}

/* jumpAndPlay */
Zanmantou.prototype.jumpAndPlay = function(index){
	this.zanmantou.JMAPI_jump(index);
}

/* setTransform */
Zanmantou.prototype.setTransform = function(ll, lr, rr, rl){
	this.zanmantou.JMAPI_setTransform(ll, lr, rr, rl);
}

/* addTrack */
Zanmantou.prototype.addTrack = function(name, url, index){
	this.zanmantou.JMAPI_addTrack(name, url, index);
}

/* removeTrack */
Zanmantou.prototype.removeTrack = function(index){
	this.zanmantou.JMAPI_removeTrack(index);
}
/* getTrackPosition */
Zanmantou.prototype.getTrackPosition = function(){
	this.register();
	this.zanmantou.JMAPI_getTrackPosition();
	return this.callbackArgs;
}
/* getTrackLength */
Zanmantou.prototype.getTrackLength = function(){
	this.register();
	this.zanmantou.JMAPI_getTrackLength();
	return this.callbackArgs;
}
/* getID3 */
Zanmantou.prototype.getID3 = function(value){
	this.register();
	this.zanmantou.JMAPI_getID3(value);
	return this.callbackArgs;
}
/* getIndex */
Zanmantou.prototype.getTrackIndex = function(){
	this.register();
	this.zanmantou.JMAPI_getTrackIndex();
	return this.callbackArgs;
}
/* getTrackName */
Zanmantou.prototype.getTrackName = function(){
	this.register();
	this.zanmantou.JMAPI_getTrackName();
	return this.callbackArgs;
}
/* getTrackFilename */
Zanmantou.prototype.getTrackFilename = function(){
	this.register();
	this.zanmantou.JMAPI_getTrackFilename();
	return this.callbackArgs;
}
/* setVolume */
Zanmantou.prototype.setVolume = function(value){
	this.zanmantou.JMAPI_setVolume(value);
}
/* setBalance */
Zanmantou.prototype.setBalance = function(value){
	this.zanmantou.JMAPI_setBalance(value);
}

/* getVolume */
Zanmantou.prototype.getVolume = function(){
	this.register();
	this.zanmantou.JMAPI_getVolume();
	return this.callbackArgs;
}
/* getBalance */
Zanmantou.prototype.getBalance = function(){
	this.register();
	this.zanmantou.JMAPI_getBalance();
	return this.callbackArgs;
}
/**************************************************************************************************/
