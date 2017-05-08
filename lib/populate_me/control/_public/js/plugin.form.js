/*!
 * jQuery Form Plugin
 * version: 2.83 (11-JUL-2011)
 * @requires jQuery v1.3.2 or later
 *
 * Examples and documentation at: http://malsup.com/jquery/form/
 * Dual licensed under the MIT and GPL licenses:
 *   http://www.opensource.org/licenses/mit-license.php
 *   http://www.gnu.org/licenses/gpl.html
 */
;(function($){$.fn.ajaxSubmit=function(w){if(!this.length){log('ajaxSubmit: skipping submit process - no element selected');return this}var x,action,url,$form=this;if(typeof w=='function'){w={success:w}}x=this.attr('method');action=this.attr('action');url=(typeof action==='string')?$.trim(action):'';url=url||window.location.href||'';if(url){url=(url.match(/^([^#]+)/)||[])[1]}w=$.extend(true,{url:url,success:$.ajaxSettings.success,type:x||'GET',iframeSrc:/^https/i.test(window.location.href||'')?'javascript:false':'about:blank'},w);var y={};this.trigger('form-pre-serialize',[this,w,y]);if(y.veto){log('ajaxSubmit: submit vetoed via form-pre-serialize trigger');return this}if(w.beforeSerialize&&w.beforeSerialize(this,w)===false){log('ajaxSubmit: submit aborted via beforeSerialize callback');return this}var n,v,a=this.formToArray(w.semantic);if(w.data){w.extraData=w.data;for(n in w.data){if(w.data[n]instanceof Array){for(var k in w.data[n]){a.push({name:n,value:w.data[n][k]})}}else{v=w.data[n];v=$.isFunction(v)?v():v;a.push({name:n,value:v})}}}if(w.beforeSubmit&&w.beforeSubmit(a,this,w)===false){log('ajaxSubmit: submit aborted via beforeSubmit callback');return this}this.trigger('form-submit-validate',[a,this,w,y]);if(y.veto){log('ajaxSubmit: submit vetoed via form-submit-validate trigger');return this}var q=$.param(a);if(w.type.toUpperCase()=='GET'){w.url+=(w.url.indexOf('?')>=0?'&':'?')+q;w.data=null}else{w.data=q}var z=[];if(w.resetForm){z.push(function(){$form.resetForm()})}if(w.clearForm){z.push(function(){$form.clearForm()})}if(!w.dataType&&w.target){var A=w.success||function(){};z.push(function(a){var b=w.replaceTarget?'replaceWith':'html';$(w.target)[b](a).each(A,arguments)})}else if(w.success){z.push(w.success)}w.success=function(a,b,c){var d=w.context||w;for(var i=0,max=z.length;i<max;i++){z[i].apply(d,[a,b,c||$form,$form])}};var B=$('input:file',this).length>0;var C='multipart/form-data';var D=($form.attr('enctype')==C||$form.attr('encoding')==C);if(w.iframe!==false&&(B||w.iframe||D)){if(w.closeKeepAlive){$.get(w.closeKeepAlive,function(){fileUpload(a)})}else{fileUpload(a)}}else{if($.browser.msie&&x=='get'){var E=$form[0].getAttribute('method');if(typeof E==='string')w.type=E}$.ajax(w)}this.trigger('form-submit-notify',[this,w]);return this;function fileUpload(a){var l=$form[0],el,i,s,g,id,$io,io,xhr,sub,n,timedOut,timeoutHandle;var m=!!$.fn.prop;if(a){for(i=0;i<a.length;i++){el=$(l[a[i].name]);el[m?'prop':'attr']('disabled',false)}}if($(':input[name=submit],:input[id=submit]',l).length){alert('Error: Form elements must not have name or id of "submit".');return}s=$.extend(true,{},$.ajaxSettings,w);s.context=s.context||s;id='jqFormIO'+(new Date().getTime());if(s.iframeTarget){$io=$(s.iframeTarget);n=$io.attr('name');if(n==null)$io.attr('name',id);else id=n}else{$io=$('<iframe name="'+id+'" src="'+s.iframeSrc+'" />');$io.css({position:'absolute',top:'-1000px',left:'-1000px'})}io=$io[0];xhr={aborted:0,responseText:null,responseXML:null,status:0,statusText:'n/a',getAllResponseHeaders:function(){},getResponseHeader:function(){},setRequestHeader:function(){},abort:function(a){var e=(a==='timeout'?'timeout':'aborted');log('aborting upload... '+e);this.aborted=1;$io.attr('src',s.iframeSrc);xhr.error=e;s.error&&s.error.call(s.context,xhr,e,a);g&&$.event.trigger("ajaxError",[xhr,s,e]);s.complete&&s.complete.call(s.context,xhr,e)}};g=s.global;if(g&&!$.active++){$.event.trigger("ajaxStart")}if(g){$.event.trigger("ajaxSend",[xhr,s])}if(s.beforeSend&&s.beforeSend.call(s.context,xhr,s)===false){if(s.global){$.active--}return}if(xhr.aborted){return}sub=l.clk;if(sub){n=sub.name;if(n&&!sub.disabled){s.extraData=s.extraData||{};s.extraData[n]=sub.value;if(sub.type=="image"){s.extraData[n+'.x']=l.clk_x;s.extraData[n+'.y']=l.clk_y}}}var o=1;var p=2;function getDoc(a){var b=a.contentWindow?a.contentWindow.document:a.contentDocument?a.contentDocument:a.document;return b}function doSubmit(){var t=$form.attr('target'),a=$form.attr('action');l.setAttribute('target',id);if(!x){l.setAttribute('method','POST')}if(a!=s.url){l.setAttribute('action',s.url)}if(!s.skipEncodingOverride&&(!x||/post/i.test(x))){$form.attr({encoding:'multipart/form-data',enctype:'multipart/form-data'})}if(s.timeout){timeoutHandle=setTimeout(function(){timedOut=true;cb(o)},s.timeout)}function checkState(){try{var a=getDoc(io).readyState;log('state = '+a);if(a.toLowerCase()=='uninitialized')setTimeout(checkState,50)}catch(e){log('Server abort: ',e,' (',e.name,')');cb(p);timeoutHandle&&clearTimeout(timeoutHandle);timeoutHandle=undefined}}var b=[];try{if(s.extraData){for(var n in s.extraData){b.push($('<input type="hidden" name="'+n+'" />').attr('value',s.extraData[n]).appendTo(l)[0])}}if(!s.iframeTarget){$io.appendTo('body');io.attachEvent?io.attachEvent('onload',cb):io.addEventListener('load',cb,false)}setTimeout(checkState,15);l.submit()}finally{l.setAttribute('action',a);if(t){l.setAttribute('target',t)}else{$form.removeAttr('target')}$(b).remove()}}if(s.forceSync){doSubmit()}else{setTimeout(doSubmit,10)}var q,doc,domCheckCount=50,callbackProcessed;function cb(e){if(xhr.aborted||callbackProcessed){return}try{doc=getDoc(io)}catch(ex){log('cannot access response document: ',ex);e=p}if(e===o&&xhr){xhr.abort('timeout');return}else if(e==p&&xhr){xhr.abort('server abort');return}if(!doc||doc.location.href==s.iframeSrc){if(!timedOut)return}io.detachEvent?io.detachEvent('onload',cb):io.removeEventListener('load',cb,false);var c='success',errMsg;try{if(timedOut){throw'timeout';}var d=s.dataType=='xml'||doc.XMLDocument||$.isXMLDoc(doc);log('isXml='+d);if(!d&&window.opera&&(doc.body==null||doc.body.innerHTML=='')){if(--domCheckCount){log('requeing onLoad callback, DOM not available');setTimeout(cb,250);return}}var f=doc.body?doc.body:doc.documentElement;xhr.responseText=f?f.innerHTML:null;xhr.responseXML=doc.XMLDocument?doc.XMLDocument:doc;if(d)s.dataType='xml';xhr.getResponseHeader=function(a){var b={'content-type':s.dataType};return b[a]};if(f){xhr.status=Number(f.getAttribute('status'))||xhr.status;xhr.statusText=f.getAttribute('statusText')||xhr.statusText}var h=s.dataType||'';var i=/(json|script|text)/.test(h.toLowerCase());if(i||s.textarea){var j=doc.getElementsByTagName('textarea')[0];if(j){xhr.responseText=j.value;xhr.status=Number(j.getAttribute('status'))||xhr.status;xhr.statusText=j.getAttribute('statusText')||xhr.statusText}else if(i){var k=doc.getElementsByTagName('pre')[0];var b=doc.getElementsByTagName('body')[0];if(k){xhr.responseText=k.textContent?k.textContent:k.innerHTML}else if(b){xhr.responseText=b.innerHTML}}}else if(s.dataType=='xml'&&!xhr.responseXML&&xhr.responseText!=null){xhr.responseXML=r(xhr.responseText)}try{q=v(xhr,s.dataType,s)}catch(e){c='parsererror';xhr.error=errMsg=(e||c)}}catch(e){log('error caught: ',e);c='error';xhr.error=errMsg=(e||c)}if(xhr.aborted){log('upload aborted');c=null}if(xhr.status){c=(xhr.status>=200&&xhr.status<300||xhr.status===304)?'success':'error'}if(c==='success'){s.success&&s.success.call(s.context,q,'success',xhr);g&&$.event.trigger("ajaxSuccess",[xhr,s])}else if(c){if(errMsg==undefined)errMsg=xhr.statusText;s.error&&s.error.call(s.context,xhr,c,errMsg);g&&$.event.trigger("ajaxError",[xhr,s,errMsg])}g&&$.event.trigger("ajaxComplete",[xhr,s]);if(g&&!--$.active){$.event.trigger("ajaxStop")}s.complete&&s.complete.call(s.context,xhr,c);callbackProcessed=true;if(s.timeout)clearTimeout(timeoutHandle);setTimeout(function(){if(!s.iframeTarget)$io.remove();xhr.responseXML=null},100)}var r=$.parseXML||function(s,a){if(window.ActiveXObject){a=new ActiveXObject('Microsoft.XMLDOM');a.async='false';a.loadXML(s)}else{a=(new DOMParser()).parseFromString(s,'text/xml')}return(a&&a.documentElement&&a.documentElement.nodeName!='parsererror')?a:null};var u=$.parseJSON||function(s){return window['eval']('('+s+')')};var v=function(a,b,s){var c=a.getResponseHeader('content-type')||'',xml=b==='xml'||!b&&c.indexOf('xml')>=0,q=xml?a.responseXML:a.responseText;if(xml&&q.documentElement.nodeName==='parsererror'){$.error&&$.error('parsererror')}if(s&&s.dataFilter){q=s.dataFilter(q,b)}if(typeof q==='string'){if(b==='json'||!b&&c.indexOf('json')>=0){q=u(q)}else if(b==="script"||!b&&c.indexOf("javascript")>=0){$.globalEval(q)}}return q}}};$.fn.ajaxForm=function(f){if(this.length===0){var o={s:this.selector,c:this.context};if(!$.isReady&&o.s){log('DOM not ready, queuing ajaxForm');$(function(){$(o.s,o.c).ajaxForm(f)});return this}log('terminating; zero elements found by selector'+($.isReady?'':' (DOM not ready)'));return this}return this.ajaxFormUnbind().bind('submit.form-plugin',function(e){if(!e.isDefaultPrevented()){e.preventDefault();$(this).ajaxSubmit(f)}}).bind('click.form-plugin',function(e){var a=e.target;var b=$(a);if(!(b.is(":submit,input:image"))){var t=b.closest(':submit');if(t.length==0){return}a=t[0]}var c=this;c.clk=a;if(a.type=='image'){if(e.offsetX!=undefined){c.clk_x=e.offsetX;c.clk_y=e.offsetY}else if(typeof $.fn.offset=='function'){var d=b.offset();c.clk_x=e.pageX-d.left;c.clk_y=e.pageY-d.top}else{c.clk_x=e.pageX-a.offsetLeft;c.clk_y=e.pageY-a.offsetTop}}setTimeout(function(){c.clk=c.clk_x=c.clk_y=null},100)})};$.fn.ajaxFormUnbind=function(){return this.unbind('submit.form-plugin click.form-plugin')};$.fn.formToArray=function(b){var a=[];if(this.length===0){return a}var c=this[0];var d=b?c.getElementsByTagName('*'):c.elements;if(!d){return a}var i,j,n,v,el,max,jmax;for(i=0,max=d.length;i<max;i++){el=d[i];n=el.name;if(!n){continue}if(b&&c.clk&&el.type=="image"){if(!el.disabled&&c.clk==el){a.push({name:n,value:$(el).val()});a.push({name:n+'.x',value:c.clk_x},{name:n+'.y',value:c.clk_y})}continue}v=$.fieldValue(el,true);if(v&&v.constructor==Array){for(j=0,jmax=v.length;j<jmax;j++){a.push({name:n,value:v[j]})}}else if(v!==null&&typeof v!='undefined'){a.push({name:n,value:v})}}if(!b&&c.clk){var e=$(c.clk),input=e[0];n=input.name;if(n&&!input.disabled&&input.type=='image'){a.push({name:n,value:e.val()});a.push({name:n+'.x',value:c.clk_x},{name:n+'.y',value:c.clk_y})}}return a};$.fn.formSerialize=function(a){return $.param(this.formToArray(a))};$.fn.fieldSerialize=function(b){var a=[];this.each(function(){var n=this.name;if(!n){return}var v=$.fieldValue(this,b);if(v&&v.constructor==Array){for(var i=0,max=v.length;i<max;i++){a.push({name:n,value:v[i]})}}else if(v!==null&&typeof v!='undefined'){a.push({name:this.name,value:v})}});return $.param(a)};$.fn.fieldValue=function(a){for(var b=[],i=0,max=this.length;i<max;i++){var c=this[i];var v=$.fieldValue(c,a);if(v===null||typeof v=='undefined'||(v.constructor==Array&&!v.length)){continue}v.constructor==Array?$.merge(b,v):b.push(v)}return b};$.fieldValue=function(b,c){var n=b.name,t=b.type,tag=b.tagName.toLowerCase();if(c===undefined){c=true}if(c&&(!n||b.disabled||t=='reset'||t=='button'||(t=='checkbox'||t=='radio')&&!b.checked||(t=='submit'||t=='image')&&b.form&&b.form.clk!=b||tag=='select'&&b.selectedIndex==-1)){return null}if(tag=='select'){var d=b.selectedIndex;if(d<0){return null}var a=[],ops=b.options;var e=(t=='select-one');var f=(e?d+1:ops.length);for(var i=(e?d:0);i<f;i++){var g=ops[i];if(g.selected){var v=g.value;if(!v){v=(g.attributes&&g.attributes['value']&&!(g.attributes['value'].specified))?g.text:g.value}if(e){return v}a.push(v)}}return a}return $(b).val()};$.fn.clearForm=function(){return this.each(function(){$('input,select,textarea',this).clearFields()})};$.fn.clearFields=$.fn.clearInputs=function(){var a=/^(?:color|date|datetime|email|month|number|password|range|search|tel|text|time|url|week)$/i;return this.each(function(){var t=this.type,tag=this.tagName.toLowerCase();if(a.test(t)||tag=='textarea'){this.value=''}else if(t=='checkbox'||t=='radio'){this.checked=false}else if(tag=='select'){this.selectedIndex=-1}})};$.fn.resetForm=function(){return this.each(function(){if(typeof this.reset=='function'||(typeof this.reset=='object'&&!this.reset.nodeType)){this.reset()}})};$.fn.enable=function(b){if(b===undefined){b=true}return this.each(function(){this.disabled=!b})};$.fn.selected=function(b){if(b===undefined){b=true}return this.each(function(){var t=this.type;if(t=='checkbox'||t=='radio'){this.checked=b}else if(this.tagName.toLowerCase()=='option'){var a=$(this).parent('select');if(b&&a[0]&&a[0].type=='select-one'){a.find('option').selected(false)}this.selected=b}})};function log(){var a='[jquery.form] '+Array.prototype.join.call(arguments,'');if(window.console&&window.console.log){window.console.log(a)}else if(window.opera&&window.opera.postError){window.opera.postError(a)}}})(jQuery);