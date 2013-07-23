$(function(){

    var chrome = navigator.userAgent.toLowerCase().indexOf('chrome') > -1;
    if (chrome) {
        jQuery(".tag_button").css("margin-top",-16);
				jQuery(".tag_button").css("margin-right",-1);
				jQuery("div.column .portlet-header select option").css("text-transform","uppercase");
    }
				 
				 
    var opera = navigator.userAgent.toLowerCase().indexOf('opera') > -1;
    if (opera) {
        jQuery("a.idea_add_link2 ").css("margin-left",5);
    }
				 
    var safari = navigator.userAgent.toLowerCase().indexOf('safari') > -1;
    if (safari) {
        jQuery("#nav li .sub").css("margin-top",-40);
        jQuery(".cb-save").css("margin-left",-79);
        jQuery(".cb-save label").css("margin-left",-76);
    }
				 
    var firefox = navigator.userAgent.toLowerCase().indexOf('firefox') > -1;
    if (firefox) {
        jQuery("#nav li .sub").css("margin-top",-40);
    }
		
    var Win = navigator.appVersion.indexOf("Win") != -1;
    if (Win && firefox) {
				/*alert("ffwin");*/
    }
				 
    var Linux = navigator.appVersion.indexOf("Linux") !=-1;
				if (Linux && chrome){
						jQuery(".fblike").css("margin-right",24);
					}

    var Linux = navigator.appVersion.indexOf("Linux") !=-1;
				if (Linux && firefox){
						jQuery(".fblike").css("margin-right",24);
					}

    var ie8com = document.documentMode && document.documentMode == 8;
    if (ie8com) {
        jQuery("a.idea_add_link2").css("margin-left",5);
				jQuery("idea_tag").css("margin-left",-40);
				jQuery(".Chapter_name").css("top",-3);
				jQuery("#idea_category input, #point_supports input, #point_opposes input").css("margin-bottom",5);
				jQuery(".point_supports_label, .point_opposes_label").css("top",-3);
				jQuery("#idea_category").css("width",650);
				jQuery("#idea_category2").css("width",670);
				jQuery(".Chapter_name_2").css("top",-2);
				jQuery(".Chapter_name_2").css("left",-2);
				jQuery("#idea_category2 input").css("margin-bottom",5);
				/*jQuery(".test").css("margin-left",60);*/
    }

		var ie7com = document.documentMode && document.documentMode == 7;
    if (ie7com) {
        jQuery("a.idea_add_link2").css("float","left");
				jQuery("a.idea_add_link2").css("margin-left",5);
				jQuery(".fblike").css("margin-top",-15);
				jQuery("#user_info_box").css("z-index",-1);
				jQuery("#user_info_box").css("position","relative");
				jQuery(".test").css("z-index",100);
				jQuery(".tag_button").css("margin-top",-15);
				jQuery(".Chapter_name").css("top",-8);
				jQuery("#idea_category input, #point_supports input").css("margin-bottom",5);
				jQuery(".point_supports_label, .point_opposes_label").css("top",-8);
				jQuery(".white_line").css("margin-top",-10);
				jQuery("#idea_category input").css("margin-left",-3);
				jQuery("#idea_category input").css("margin-right",-3);
				jQuery(".Chapter_name_2").css("top",-11);
				jQuery("#idea_category2").css("width",600);
				jQuery("div.column .portlet-header select").css("margin-top",-15);
				jQuery(".gt_text").css("margin-top",0);
				jQuery(".cb").css("margin-top",-2);
				jQuery(".cb").css("margin-left",-8);
				jQuery(".cb").css("margin-right",-2);
				jQuery(".cb").css("padding-left",3);
				jQuery(".addwrapper").css("margin-top",35);
				jQuery(".bellow_translate").css("margin-top",10);
				jQuery(".bellow_translate").css("width",200);
				jQuery(".bellow_translate").css("margin-left",-17);
				jQuery(".bellow_translate").css("position","relative");
				jQuery(".test").css("margin-left",-10);
				jQuery(".warning_inline").css("position","absolute");
				jQuery(".warning_inline").css("font-size",20);
    }


    var ie9com = document.documentMode && document.documentMode == 9;
    if (ie9com) {
				jQuery(".gt_text").css("margin-top",0);
				jQuery(".cb").css("margin-top",-2);
				jQuery(".cb").css("margin-left",-8);
				jQuery(".cb").css("margin-right",-2);
				jQuery(".cb").css("padding-left",3);
				jQuery(".Chapter_name").css("top",-3);
				jQuery(".Chapter_name").css("left",-3);
				jQuery("#idea_category input, #point_supports input").css("margin-bottom",3);
				jQuery("#idea_category").css("width",670);
				jQuery(".Chapter_name_2").css("top",-2);
				jQuery(".Chapter_name_2").css("left",-2);
				jQuery("#idea_category2").css("width",670);
				jQuery("#idea_category2 input").css("margin-bottom",5);
				/*jQuery(".test").css("margin-left",63);*/
    }
    
				
    if(jQuery.browser.version.substring(0, 2) == "8.") {
        jQuery("#nav li .sub").css("margin-top",-39);
        jQuery(".cb-save").css("margin-left",-79);
        jQuery(".cb-save label").css("margin-left",-76);
				jQuery(".gt_text").css("margin-top",0);
				jQuery(".cb").css("margin-top",-2);
				jQuery(".cb").css("margin-left",-8);
				jQuery(".cb").css("margin-right",-2);
				jQuery(".cb").css("padding-left",3);
    }
		
});
