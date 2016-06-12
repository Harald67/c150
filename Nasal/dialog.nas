
# dialogs ===========================================================

var dialog = nil;
var name = "c150-config";

var showDialog = func {
	if (dialog != nil) {
		fgcommand("dialog-close", props.Node.new({ "dialog-name" : name }));
		dialog = nil;
	}
    createDialog();
};

var createDialog = func {
	if (dialog != nil) {
		fgcommand("dialog-close", props.Node.new({ "dialog-name" : name }));
		dialog = nil;
		return;
	}
	dialog = gui.Widget.new();
	dialog.set("layout", "vbox");
	dialog.set("name", name);

	# "window" titlebar
	titlebar = dialog.addChild("group");
	titlebar.set("layout", "hbox");
	titlebar.addChild("text").set("label", "____________C150 configuration____________");
	titlebar.addChild("empty").set("stretch", 1);

	dialog.setColor(0.6, 0.65, 0.55, 0.85);

	w = titlebar.addChild("button");
	w.set("pref-width", 16);
	w.set("pref-height", 16);
	w.set("legend", "");
	w.set("default", 1);
	w.set("border", 1);
	w.prop().getNode("binding[0]/command", 1).setValue("nasal");
	w.prop().getNode("binding[0]/script", 1).setValue("c150.dialog = nil");
	w.prop().getNode("binding[1]/command", 1).setValue("dialog-close");

	checkbox = func {
		group = dialog.addChild("group");
		group.set("layout", "hbox");
		group.addChild("empty").set("pref-width", 4);
		box = group.addChild("checkbox");
		group.addChild("empty").set("stretch", 1);

		box.set("halign", "left");
		box.set("label", arg[0]);
		box;
	}
    button = func {
	    w = dialog.addChild("button");
#	    w.set("pref-width", 16);
#	    w.set("pref-height", 16);
	    w.set("legend", arg[0]);
#	    w.set("default", 1);
	    w.set("border", 1);
		w.set("label", "");
		if( arg[2] != nil ) {
			dialog.addChild("text").set("label", arg[2]);
			dialog.addChild("empty").set("stretch", 1);
		}

	    w.prop().getNode("binding[0]/command", 1).setValue("nasal");
	    w.prop().getNode("binding[0]/script", 1).setValue(arg[1]);
	    w.prop().getNode("binding[1]/command", 1).setValue("dialog-close");
    }

    w = button( "Cold start", "c150.cold_start();" ,
        "Engine off, all switches off, parking break set");
    w = button( "Hot start", "c150.hot_start();" , 
        "Press the 's' key to start the engine");

	# doors
	foreach (d; doors) {
		w = checkbox(d.node.getNode("name").getValue());
		w.set("property", d.node.getNode("position-norm").getPath());
		w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
	}

	# lights
	w = checkbox("beacons");
	w.set("property", "controls/lighting/beacon");
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");

	w = checkbox("strobes");
	w.set("property", "controls/lighting/strobe");
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");

    # flashlight
    w = button( "Toggle flashlight", "c150.toggle_flashlight();" , 
        "Toggle ALS flashlight");



	# yoke
	w = checkbox("Show yokes");
	w.set("property", "sim/model/c150/options/show-yoke");
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");

	# finale
	dialog.addChild("empty").set("pref-height", "3");
	fgcommand("dialog-new", dialog.prop());
	gui.showDialog(name);
}
