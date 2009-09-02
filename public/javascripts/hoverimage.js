/*
Simple Image Trail script- By JavaScriptKit.com
Visit http://www.javascriptkit.com for this script and more
This notice must stay intact
*/

var offsetfrommouse=[10,10]; //image x,y offsets from cursor position in pixels. Enter 0,0 for no offset
var displayduration=0; //duration in seconds image should remain visible. 0 for always.
var currentimageheight = 400;	// maximum image size.

if (document.getElementById || document.all){
    document.write('<div id="trailimageid">');
    document.write('</div>');
}

function gettrailobj(){
    if (document.getElementById)
        return document.getElementById("trailimageid").style
    else if (document.all)
        return document.all.trailimagid.style
}

function gettrailobjnostyle(){
    if (document.getElementById)
        return document.getElementById("trailimageid")
    else if (document.all)
        return document.all.trailimagid
}


function truebody(){
    return document.body;
    // geht nicht für Safari return (!window.opera && document.compatMode && document.compatMode!="BackCompat")? document.documentElement : document.body
}

function showtrail(imagename,title,description,showthumb,height,filetype){
    if (height > 0){
        currentimageheight = height;
    }
    
    document.onmousemove=followmouse;
    
    newHTML = '<div style="padding:2px; color:white; background-color:#222; border:2px solid #555;">';
    newHTML = newHTML + '<h3 style="color:white;margin:2px;">' + title + '</h3>';
    newHTML = newHTML + '<p style="margin:2px;max-width:350px;">' + description.replace(/\[[^\]]*\]/g, '') + '<p/>';
    
    if (showthumb > 0){
        newHTML = newHTML + '<div style="text-align: center; padding: 1px 2px 0px 2px;">';
        if(filetype == 8) { // Video
            newHTML = newHTML + '<object width="380" height="285" classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=6,0,0,0">';
            newHTML = newHTML + '<param name="movie" value="video_loupe.swf">';
            newHTML = newHTML + '<param name="quality" value="best">';
            newHTML = newHTML + '<param name="loop" value="true">';
            
            newHTML = newHTML + '<param name="FlashVars" value="videoLocation=' + imagename + '&bufferPercent=25">';
            newHTML = newHTML + '<EMBED SRC="video_loupe.swf" LOOP="true" QUALITY="best" FlashVars="videoLocation=' + imagename + '&bufferPercent=25" WIDTH="380" HEIGHT="285">';
            newHTML = newHTML + '</object></div>';
        } else {
        newHTML = newHTML + '<img src="' + imagename + '" alt="' + title + '" /></div>';
        }
    }

    newHTML = newHTML + '</div>';
    gettrailobjnostyle().innerHTML = newHTML;
    gettrailobj().display="inline";
}

function hidetrail(){
    gettrailobj().innerHTML = " ";
    gettrailobj().display="none"
    document.onmousemove=""
    gettrailobj().left="-500px"
    
}

function followmouse(e){
    
    var xcoord=offsetfrommouse[0]
    var ycoord=offsetfrommouse[1]
    
    var docwidth=document.all? truebody().scrollLeft+truebody().clientWidth : pageXOffset+window.innerWidth-15
    var docheight=document.all? Math.min(truebody().scrollHeight, truebody().clientHeight) : Math.min(window.innerHeight)
    
    var padding_bottom = 50
    
    //if (document.all){
    //	gettrailobjnostyle().innerHTML = 'A = ' + truebody().scrollHeight + '<br>B = ' + truebody().clientHeight;
    //} else {
    //	gettrailobjnostyle().innerHTML = 'C = ' + document.body.offsetHeight + '<br>D = ' + window.innerHeight;
    //}
    
    if (typeof e != "undefined"){
        if (docwidth - e.pageX < 380){
            xcoord = e.pageX - xcoord - 400; // Move to the left side of the cursor
        } else {
            xcoord += e.pageX;
        }
        if (docheight - e.pageY < (currentimageheight + padding_bottom)){
            ycoord += e.pageY - Math.max(0,(padding_bottom + currentimageheight + e.pageY - docheight - truebody().scrollTop));
        } else {
            ycoord += e.pageY;
        }
    } else if (typeof window.event != "undefined"){
        if (docwidth - event.clientX < 380){
            xcoord = event.clientX + truebody().scrollLeft - xcoord - 400; // Move to the left side of the cursor
        } else {
            xcoord += truebody().scrollLeft+event.clientX
        }
        if (docheight - event.clientY < (currentimageheight + padding_bottom)){
            ycoord += event.clientY + truebody().scrollTop - Math.max(0,(padding_bottom + currentimageheight + event.clientY - docheight));
        } else {
            ycoord += truebody().scrollTop + event.clientY;
        }
    }

    if(ycoord < 0) { ycoord = ycoord*-1; }
    gettrailobj().left=xcoord+"px"
    gettrailobj().top=ycoord+"px"
}

function followmouseBatch(e){
    var xcoord=offsetfrommouse[0]
    var ycoord=offsetfrommouse[1]
    
    var docwidth=document.all? truebody().scrollLeft+truebody().clientWidth : pageXOffset+window.innerWidth-15
    var docheight=document.all? Math.min(truebody().scrollHeight, truebody().clientHeight) : Math.min(window.innerHeight)
    
    var trailInnerDiv = $('trailInnerDiv');
    var currentimageheight = trailInnerDiv.offsetHeight;
    var currentimagewidth = trailInnerDiv.offsetWidth;
    
    scrollPos = Position.realOffset(truebody());
    
    if (typeof e != "undefined"){
        if (docwidth - e.pageX < 380){
            xcoord = e.pageX - xcoord - 400; // Move to the left side of the cursor
        } else {
            xcoord += e.pageX;
        }
        if ((e.pageY - scrollPos[1]) + currentimageheight > docheight){
            ycoord = -ycoord + (e.pageY - currentimageheight);
        } else {
            ycoord += e.pageY;
        }
    } else if (typeof window.event != "undefined"){
        if (event.clientX + currentimagewidth > docwidth){
            xcoord = -xcoord + ((event.clientX + scrollPos[0]) - currentimagewidth); // Move to the left side of the cursor
        } else {
            xcoord += (event.clientX + scrollPos[0]);
        }
        if (event.clientY + currentimageheight > docheight){
            ycoord = -ycoord + ((event.clientY + scrollPos[1]) - currentimageheight);
        } else {
            ycoord += (event.clientY + scrollPos[1]);
        }
    }

    if(ycoord < 0) { ycoord = ycoord*-1; }

    gettrailobj().left=xcoord+"px"
    gettrailobj().top=ycoord+"px"
}
