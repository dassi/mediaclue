/*
Simple Image Trail script- By JavaScriptKit.com
Visit http://www.javascriptkit.com for this script and more
This notice must stay intact
*/

var offsetfrommouse=[10,10]; //image x,y offsets from cursor position in pixels. Enter 0,0 for no offset
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


function showtrail(imagename,title,description,showthumb,height){
    if (height > 0) {
        currentimageheight = height;
    }
    
    document.onmousemove = followmouse;
    
    newHTML = '<div style="padding:2px; color:white; background-color:#222; border:2px solid #555;">';
    newHTML = newHTML + '<h3 style="color:white;margin:2px;">' + title + '</h3>';
    newHTML = newHTML + '<p style="margin:2px;max-width:350px;">' + description.replace(/\[[^\]]*\]/g, '') + '<p/>';
    
    if (showthumb) {
        newHTML = newHTML + '<div style="text-align: center; padding: 1px 2px 0px 2px;">';
        newHTML = newHTML + '<img src="' + imagename + '" alt="' + title + '" /></div>';
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
    
    
    var padding_bottom = 0
    
    if (typeof e != "undefined"){
        var body = document.body
        var docwidth = body.scrollLeft+body.clientWidth
        var docheight = Math.min(body.scrollHeight, body.clientHeight)
      
        if (docwidth - e.pageX < 380){
            xcoord = e.pageX - xcoord - 400; // Move to the left side of the cursor
        } else {
            xcoord += e.pageX;
        }
        if (docheight - e.pageY < currentimageheight){
            ycoord += e.pageY - currentimageheight;
        } else {
            ycoord += e.pageY;
        }
    } else if (typeof window.event != "undefined"){ // IE
        var body = document.documentElement
        var docwidth = body.scrollLeft+body.clientWidth
        var docheight = Math.min(body.scrollHeight, body.clientHeight)

        if (docwidth - event.clientX < 380){
            xcoord = event.clientX + body.scrollLeft - xcoord - 400; // Move to the left side of the cursor
        } else {
            xcoord += body.scrollLeft+event.clientX
        }
        if (docheight - (event.clientY) < currentimageheight){
            ycoord += body.scrollTop + event.clientY - currentimageheight;
        } else {
            ycoord += body.scrollTop + event.clientY;
        }
    }

    if(ycoord < 0) { ycoord = ycoord*-1; }
    gettrailobj().left=xcoord+"px"
    gettrailobj().top=ycoord+"px"
}

