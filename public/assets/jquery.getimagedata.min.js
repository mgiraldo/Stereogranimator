/*
 *
 *  jQuery $.getImageData Plugin 0.3
 *  http://www.maxnov.com/getimagedata
 *  
 *  Written by Max Novakovic (http://www.maxnov.com/)
 *  Date: Thu Jan 13 2011
 *  Modified by Mauricio Giraldo (http://www.mauriciogiraldo.com) to remove server URL "validation"
 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *  
 *  Includes jQuery JSONP Core Plugin 2.1.4
 *  http://code.google.com/p/jquery-jsonp/
 *  Copyright 2010, Julian Aubourg
 *  Released under the MIT License.
 * 
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *  
 *  Copyright 2011, Max Novakovic
 *  Dual licensed under the MIT or GPL Version 2 licenses.
 *  http://www.maxnov.com/getimagedata/#license
 * 
 */
(function(a,b){function c(){}function d(a){x=[a]}function e(a,b,c){return a&&a.apply(b.context||b,c)}function f(f){function z(a){!(Z++)&&b(function(){$(),R&&(v[V]={s:[a]}),F&&(a=F.apply(f,[a])),e(f.success,f,[a,r]),e(E,f,[f,r])},0)}function B(a){!(Z++)&&b(function(){$(),R&&a!=s&&(v[V]=a),e(f.error,f,[f,a]),e(E,f,[f,a])},0)}f=a.extend({},y,f);var E=f.complete,F=f.dataFilter,G=f.callbackParameter,H=f.callback,O=f.cache,R=f.pageCache,U=f.charset,V=f.url,W=f.data,X=f.timeout,Y,Z=0,$=c;return f.abort=function(){!(Z++)&&$()},e(f.beforeSend,f,[f])===!1||Z?f:(V=V||i,W=W?typeof W=="string"?W:a.param(W,f.traditional):i,V+=W?(/\?/.test(V)?"&":"?")+W:i,G&&(V+=(/\?/.test(V)?"&":"?")+encodeURIComponent(G)+"=?"),!O&&!R&&(V+=(/\?/.test(V)?"&":"?")+"_"+(new Date).getTime()+"="),V=V.replace(/=\?(&|$)/,"="+H+"$1"),R&&(Y=v[V])?Y.s?z(Y.s[0]):B(Y):b(function(e,f,i){if(!Z){i=X>0&&b(function(){B(s)},X),$=function(){i&&clearTimeout(i),e[o]=e[l]=e[n]=e[m]=null,u[p](e),f&&u[p](f)},window[H]=d,e=a(q)[0],e.id=k+w++,U&&(e[h]=U);var r=function(a){(e[l]||c)(),a=x,x=undefined,a?z(a[0]):B(j)};t.msie?(e.event=l,e.htmlFor=e.id,e[o]=function(){/loaded|complete/.test(e.readyState)&&r()}):(e[m]=e[n]=r,t.opera?(f=a(q)[0]).text="jQuery('#"+e.id+"')[0]."+m+"()":e[g]=g),e.src=V,u.insertBefore(e,u.firstChild),f&&u.insertBefore(f,u.firstChild)}},0),f)}var g="async",h="charset",i="",j="error",k="_jqjsp",l="onclick",m="on"+j,n="onload",o="onreadystatechange",p="removeChild",q="<script/>",r="success",s="timeout",t=a.browser,u=a("head")[0]||document.documentElement,v={},w=0,x,y={callback:k,url:location.href};f.setup=function(b){a.extend(y,b)},a.jsonp=f})(jQuery,setTimeout),function(a){a.getImageData=function(b){var d=/(ftp|http|https):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/;if(b.url){var e=location.protocol==="https:",f="";f=b.server&&d.test(b.server)&&b.server.indexOf("https:")&&(e||b.url.indexOf("https:"))?b.server:b.server,a.jsonp({url:f,data:{url:b.url},dataType:"jsonp",timeout:1e4,success:function(d){var e=new Image;a(e).load(function(){this.width=d.width,this.height=d.height,typeof b.success==typeof Function&&b.success(this)}).attr("src",d.data)},error:function(a,c){typeof b.error==typeof Function&&b.error(a,c)}})}else typeof b.error==typeof Function&&b.error(null,"no_url")}}(jQuery);