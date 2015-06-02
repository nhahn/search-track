$(document).ready(function(){
	if ($('.esotericsidebarname').css('bottom') == '-260px') 
		$(".esotericsidebarname").animate({"bottom": "+=275px"});
 	else $(".esotericsidebarname").animate({"bottom": "-=275px"});
});
