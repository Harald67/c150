
optarg = aircraft.optarg;
makeNode = aircraft.makeNode;

last_time  = 0.0;
DTOR       = math.pi / 180.0;
starterN   = props.globals.getNode("controls/engines/engine/starter", 1);
primerN    = props.globals.getNode("controls/engines/engine/primer", 1);
MixtureLever = props.globals.getNode("controls/engines/engine[0]/mixture-lever", 1);
fdmMixture = props.globals.getNode("controls/engines/engine[0]/mixture", 1);
rpmN       = props.globals.getNode("engines/engine[0]/rpm", 1);
refTemp    = props.globals.getNode("engines/engine/oil-temperature-degf", 1);
#refTemp    = props.globals.getNode("engines/engine/egt-degf", 1);
airTempN   = props.globals.getNode("environment/temperature-degf", 1);
voltN      = props.globals.getNode("systems/electrical/outputs/bus[0]", 1);
altSwN     = props.globals.getNode("controls/engines/engine[0]/master-alt", 1);
batSwN     = props.globals.getNode("controls/engines/engine[0]/master-bat", 1);
surtensionN= props.globals.getNode("sim/model/c150/surtension-light", 1);
hmHobbs    = props.globals.getNode("sim/model/c150/instrument/time-hobbs-meter", 1);
hmTach     = props.globals.getNode("sim/model/c150/instrument/time-tach-meter", 1);

pumpPrimer = func {
    if (getprop("controls/engines/engine/primer-pump") == 0){
        setprop("controls/engines/engine/primer-pump",1);
    }
    else
    {
        setprop("controls/engines/engine/primer-pump",0);
        pump = primerN.getValue() + 1;
        primerN.setValue( pump );
    }
}



# strobes ===========================================================
strobe_switch = props.globals.getNode("controls/lighting/strobe", 1);
#aircraft.light.new("sim/model/bo105/lighting/strobe-top", [0.05, 1.00], strobe_switch);
#aircraft.light.new("sim/model/bo105/lighting/strobe-bottom", [0.05, 1.03], strobe_switch);

# beacons ===========================================================
beacon_switch = props.globals.getNode("controls/lighting/beacon", 1);
#aircraft.light.new("sim/model/bo105/lighting/beacon-top", [0.62, 0.62], beacon_switch);
#aircraft.light.new("sim/model/bo105/lighting/beacon-bottom", [0.63, 0.63], beacon_switch);



# nav lights ========================================================
nav_light_switch = props.globals.getNode("controls/lighting/nav-lights", 1);
visibility = props.globals.getNode("environment/visibility-m", 1);
sun_angle = props.globals.getNode("sim/time/sun-angle-rad", 1);
nav_lights = props.globals.getNode("sim/model/c150/lighting/nav-lights", 1);

nav_light_loop = func {
	if (nav_light_switch.getValue()) {
		nav_lights.setValue(visibility.getValue() < 5000 or sun_angle.getValue() > 1.4);
	} else {
		nav_lights.setValue(0);
	}
	settimer(nav_light_loop, 3);
}




# doors =============================================================
active_door = 0;
doors = [];

init_doors = func {
	foreach (d; props.globals.getNode("sim/model/c150/doors").getChildren("door")) {
		append(doors, aircraft.door.new(d, 2.5));
	}
}

next_door = func { select_door(active_door + 1) }

previous_door = func { select_door(active_door - 1) }

select_door = func {
	active_door = arg[0];
	if (active_door < 0) {
		active_door = size(doors) - 1;
	} elsif (active_door >= size(doors)) {
		active_door = 0;
	}
	gui.popupTip("Selecting " ~ doors[active_door].node.getNode("name").getValue());
}

toggle_door = func {
	doors[active_door].toggle();
}


variant = nil;


# dialogs ===========================================================
dialog = nil;

showDialog = func {
	name = "c150-config";
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

	# doors
	foreach (d; doors) {
#		w = checkbox(d.node.getNode("name").getValue());
#		w.set("property", d.node.getNode("enabled").getPath());
#		w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
	}

    w = button( "Cold start", "c150.cold_start();" ,
	"Engine off, all switches off, parking break set");
    w = button( "Hot start", "c150.hot_start();" , 
	"Press the space bar to start the engine");

	# lights
#	w = checkbox("beacons");
#	w.set("property", "controls/lighting/beacon");
#	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");

#	w = checkbox("strobes");
#	w.set("property", "controls/lighting/strobe");
#	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");


	# yoke
	w = checkbox("Show yokes");
	w.set("property", "sim/model/c150/options/show-yoke");
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");

	# finale
	dialog.addChild("empty").set("pref-height", "3");
	fgcommand("dialog-new", dialog.prop());
	gui.showDialog(name);
}

controls.mixtureAxis = func {
    val = cmdarg().getNode("setting").getValue();
    if(size(arg) > 0) { val = -val; }
    props.setAll("/controls/engines/engine", "mixture-lever", (1 - val)/2);
}

# simulate fuel cut off due to lack of gravity
# simulate engine cold start
calcMixture = func {
    gg = - getprop("/fdm/jsbsim/accelerations/n-pilot-z-norm");
    # compute this value since jsbsim does not export it here
    # need to check the AS or else any bump in terrain will cut the fuel flow
    g = 0.9 * getprop("accelerations/pilot-g") + 0.1 * gg;
    setprop("accelerations/pilot-g", g);
    if (g > 0.75) {
        mixture = 1.0;
    }
    elsif (g <= 0.75 and g >= 0)  {            # mixture set by - ve g
        mixture = g * 4/3;
    }
    else  {                                    # mixture set by - ve g
        mixture = 0.0;
    }
    mixture = mixture * MixtureLever.getValue();
    # 298 K == 77 F == 25 C
    engineTemp = refTemp.getValue();
    pump = primerN.getValue();
    if( getprop( "engines/engine/running") == 0) {
        if( pump > 7) {
            # flooding
            mixture = 0;
        }
        if( engineTemp <= 40 ) {
            if( pump < 5) {
                mixture = 0;
            }
            # up to 6 primer
        } elsif ( engineTemp <= 65 ) {
            # 1 or 2 primer
            if( pump < 1) {
                mixture = 0;
            }
        }
    } else {
        primerN.setValue( 0 );
    }
    if( starterN.getValue() ) {
        print("engineTemp=", engineTemp, " pump=", pump, " => mixture=", mixture);
        primerN.setValue( pump - 0.2);
        if( primerN.getValue() < 0 ) {
            primerN.setValue( 0 );
        }
    }
    fdmMixture.setValue( mixture );
}

calcEC = func {
    if( voltN.getValue() <= 8.0 ) {
        fdmMixture.setValue( 0.0 );
    }
    if( !altSwN.getValue() and batSwN.getValue()) {
        # led test
        surtensionN.setValue( voltN.getValue() );
    } else {
        surtensionN.setValue( 0.0 );
    }
}

calcDigits = func( v, prop, ndigit ) {
    v = int( v );
    for( var i = 0; i < ndigit ; i=i+1 ) {
        v2 = int( v / 10 );
        r = v - v2 * 10;
        setprop( prop~i, r );
        v = v2;
    }
}

calcHoursMeter = func(dt) {
    var t = hmHobbs.getValue();
    if( rpmN.getValue() > 100.0 ) {
        t = t + dt;
        hmHobbs.setValue( t );
    }
    calcDigits( int(t / 3600), "/instrumentation/hobbs-meter/digits", 6);
    var q = hmTach.getValue() + dt * rpmN.getValue() / 2566.0;
    hmTach.setValue( q );
    calcDigits( int(q / 3600), "/instrumentation/tach-meter/digits", 6);
}

system_loop = func {

    time = getprop("/sim/time/elapsed-sec");
    dt = time - last_time;
    last_time = time;

    calcMixture();
    calcEC();
    calcHoursMeter( dt );

    ldoorw = 0.0;
    rdoorw = 0.0;
    if( getprop("sim/model/c150/doors/door[0]/position-norm") > 0.0 ) { ldoorw += 1.0; }
    elsif( getprop("sim/model/c150/doors/door[2]/position-norm") > 0.0 ) { ldoorw += 0.5; }
    if( getprop("sim/model/c150/doors/door[1]/position-norm") > 0.0 ) { rdoorw += 1.0; }
    elsif( getprop("sim/model/c150/doors/door[3]/position-norm") > 0.0 ) { rdoorw += 0.5; }
    setprop("sim/model/c150/doors/doorw", ldoorw + rdoorw);

    calcRollSpeed(dt);
    settimer(system_loop, 0.1);
}


# reset code ========================================================
cold_start = func {
	print("cold start");
	setprop("controls/gear/brake-parking", 1);
	setprop("accelerations/pilot-g", 1.0);
	setprop("controls/engines/engine/primer", 0);
	setprop("controls/engines/engine/primer-pump", 0);
	MixtureLever.setValue(0.0);
	fdmMixture.setValue(0.0);
	rpmN.setValue( 0.0 );
	setprop("controls/engines/engine/magnetos", 0);
	setprop("controls/engines/engine/master-alt", 0);
	setprop("controls/engines/engine/master-bat", 0);
	setprop("engines/engine/running", 0);
	setprop("controls/engines/engine/throttle", 0.0);
}

hot_start = func {
	cold_start();
	print("hot start");
	fdmMixture.setValue(1.0);
	MixtureLever.setValue(1.0);
	rpmN.setValue( 700.0 );
	setprop("controls/engines/engine/magnetos", 3);
	setprop("controls/engines/engine/master-alt", 1);
	setprop("controls/engines/engine/master-bat", 1);
	setprop("controls/engines/engine/primer", 2);
	setprop("engines/engine/running", 1);
	setprop("controls/engines/engine/throttle", 0.5);
}

# main() ============================================================
crashed = props.globals.getNode("sim/crashed", 1);
reset = props.globals.getNode("sim/model/c150/reset", 1);

main_loop = func {
	if (crashed.getValue()) {
		crash();
	} elsif (reset.getValue()) {
		on_menu_reset();
	}
	settimer(main_loop, 0.5);
}


crash = func {
    print("crashed ?");
    reset.setIntValue(1);
}

on_menu_reset = func {
	reset.setIntValue(0);
	cold_start();
}

calcRollSpeed = func(dt) {
	mps = getprop("velocities/uBody-fps") * 0.3048;
	foreach (g; props.globals.getNode("gear").getChildren("gear")) {
		computeRollSpeedforGear(g, mps, dt);
	}
}

computeRollSpeedforGear = func(g, mps, dt) {
	wow = g.getNode("wow").getValue();
	if( wow ) {
		g.getNode("rollspeed-ms").setValue(mps);
	} else {
		newspeed = 0.90 * g.getNode("rollspeed-ms").getValue();
		g.getNode("rollspeed-ms").setValue(newspeed);
	}
}


setlistener("/sim/signals/fdm-initialized", func {
    on_menu_reset();
    settimer(main_loop, 1.0);
    settimer(system_loop, 1.0);
    settimer(nav_light_loop, 3.0);
    settimer(init_doors, 0.7);
    settimer(showDialog, 1.0);
});
