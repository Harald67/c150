
#optarg = aircraft.optarg;
#makeNode = aircraft.makeNode;

var last_time  = 0.0;
var DTOR       = math.pi / 180.0;
var starterN   = props.globals.getNode("controls/engines/engine/starter", 1);
var primerN    = props.globals.getNode("controls/engines/engine/primer", 1);
var MixtureLever = props.globals.getNode("controls/engines/engine[0]/mixture-lever", 1);
var fdmMixture = props.globals.getNode("controls/engines/engine[0]/mixture", 1);
var rpmN       = props.globals.getNode("engines/engine[0]/rpm", 1);
var refTemp    = props.globals.getNode("engines/engine/oil-temperature-degf", 1);
#refTemp    = props.globals.getNode("engines/engine/egt-degf", 1);
var airTempN   = props.globals.getNode("environment/temperature-degf", 1);
var voltN      = props.globals.getNode("/systems/electrical/volts", 1);
var altSwN     = props.globals.getNode("controls/engines/engine[0]/master-alt", 1);
var batSwN     = props.globals.getNode("controls/engines/engine[0]/master-bat", 1);
var surtensionN= props.globals.getNode("sim/model/c150/surtension-light", 1);
var hmHobbs    = props.globals.getNode("sim/model/c150/instrument/time-hobbs-meter", 1);
var hmTach     = props.globals.getNode("sim/model/c150/instrument/time-tach-meter", 1);

controls.startEngine = func(n) {
setprop("/controls/engines/engine/starter-key", n);
}

# called from key Shift-o binding and lever pick animation
var pumpPrimer = func {
    if (getprop("controls/engines/engine/primer-pump") == 0){
        setprop("controls/engines/engine/primer-pump",1);
        # PlaySound("lever_out", 0.9);
    }
    else
    {
        setprop("controls/engines/engine/primer-pump",0);
        pump = primerN.getValue() + 1;
        primerN.setValue( pump );
        # PlaySound("lever_in", 0.9);
    }
}



# strobes ===========================================================
strobe_switch = props.globals.getNode("controls/lighting/strobe", 1);
#aircraft.light.new("sim/model/bo105/lighting/strobe-top", [0.05, 1.00], strobe_switch);
#aircraft.light.new("sim/model/bo105/lighting/strobe-bottom", [0.05, 1.03], strobe_switch);

# beacons ===========================================================
beacon_switch = props.globals.getNode("/systems/electrical/outputs/beacon", 1);
aircraft.light.new("/sim/model/c150/lighting/beacon", [0.10, 0.90], beacon_switch);



# nav lights ========================================================

var NavLights = {
    nav_light_switch : props.globals.getNode("/systems/electrical/outputs/navigation-light", 1),
    visibility : props.globals.getNode("environment/visibility-m", 1),
    sun_angle  : props.globals.getNode("sim/time/sun-angle-rad", 1),
    nav_lights : props.globals.getNode("sim/model/c150/lighting/nav-lights", 1),

    nav_light_loop : func {
        if (me.nav_light_switch.getValue()) {
            me.nav_lights.setValue(me.visibility.getValue() < 5000 or me.sun_angle.getValue() > 1.4);
        } else {
            me.nav_lights.setValue(0);
        }
        settimer(func {me.nav_light_loop();}, 3);
    },
};



# doors =============================================================

var active_door = 0;
var doors = [];
var rightDoor = nil;
var leftDoor = nil;
var rightWindow = nil;
var leftWindow = nil;

var init_doors = func {
    foreach (d; props.globals.getNode("sim/model/c150/doors").getChildren("door")) {
        append(doors, aircraft.door.new(d, 2.5));
    }
    leftDoor = doors[0];
    rightDoor = doors[1];
    leftWindow = doors[2];
    rightWindow = doors[3];
}

var select_door = func {
    active_door = arg[0];
    if (active_door < 0) {
        active_door = size(doors) - 1;
    } elsif (active_door >= size(doors)) {
        active_door = 0;
    }
    gui.popupTip("Selecting " ~ doors[active_door].node.getNode("name").getValue());
}

# called from key d binding
var next_door = func { select_door(active_door + 1) }

# called from key Shift-d binding
var previous_door = func { select_door(active_door - 1) }

# called from key Ctrl-d binding
var toggle_door = func {
    if(doors[active_door] == leftWindow) {
        if( getprop("controls/windows/windowL-angle") < 5 ) {
            interpolate("controls/windows/windowL-angle", 30, 2.0);
            doors[active_door].open();
        } else {
            interpolate("controls/windows/windowL-angle", 0, 2.0);
            doors[active_door].close();
        }
    } elsif(doors[active_door] == rightWindow) {
        if( getprop("controls/windows/windowR-angle") < 5 ) {
            interpolate("controls/windows/windowR-angle", 30, 2.0);
            doors[active_door].open();
        } else {
            interpolate("controls/windows/windowR-angle", 0, 2.0);
            doors[active_door].close();
        }
    } else 
        doors[active_door].toggle();
}


var Doors = {
	new: func {
		var m = { parents: [Doors] };
		m.active = 0;
		m.list = [];
		foreach (var d; props.globals.getNode("sim/model/c150/doors").getChildren("door"))
			append(m.list, aircraft.door.new(d, 2.5));
		return m;
	},
	next: func {
		me.select(me.active + 1);
	},
	previous: func {
		me.select(me.active - 1);
	},
	select: func(which) {
		me.active = which;
		if (me.active < 0)
			me.active = size(me.list) - 1;
		elsif (me.active >= size(me.list))
			me.active = 0;
		gui.popupTip("Selecting " ~ me.list[me.active].node.getNode("name").getValue());
	},
	toggle: func {
		me.list[me.active].toggle();
	},
	reset: func {
		foreach (var d; me.list)
			d.setpos(0);
	},
};

var variant = nil;

# mixture ===========================================================

controls.mixtureAxis = func {
    val = cmdarg().getNode("setting").getValue();
    if(size(arg) > 0) { val = -val; }
    props.setAll("/controls/engines/engine", "mixture-lever", (1 - val)/2);
}
controls.adjMixture = func(speed) {
    controls.adjEngControl("mixture-lever", speed); 
    if( MixtureLever.getValue() < 0.0 )
        MixtureLever.setValue(0.0);
    if( MixtureLever.getValue() > 1.0 )
        MixtureLever.setValue(1.0);
}

var old_stepMagnetos = controls.stepMagnetos;
controls.stepMagnetos = func(change) {
    var new_value = getprop("controls/engines/engine/c150-magnetos") + change;
    if( new_value >= 0 and new_value <= 3)
        setprop("controls/engines/engine/c150-magnetos", new_value);
    old_stepMagnetos(change);
}

# simulate fuel cut off due to lack of gravity
# simulate engine cold start
var calcMixture = func(dt) {
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
    # carb heat should reduce the RPM
    if(getprop("controls/anti-ice/engine[0]/carb-heat") > 0)
        mixture = mixture * 0.90;

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
        primerN.setValue( pump - dt);
        if( primerN.getValue() < 0 ) {
            primerN.setValue( 0 );
        }
    }
    fdmMixture.setValue( mixture );
}

var calcEC = func(dt) {
#    if( voltN.getValue() <= 8.0 ) {
#        fdmMixture.setValue( 0.0 );
#    }
    if( getprop("/systems/electrical/power-source") == "battery" ) {
        # led test
        surtensionN.setValue( voltN.getValue() );
    } else {
        surtensionN.setValue( 0.0 );
    }
}

var calcDigits = func( v, prop, ndigit ) {
    v = int( v );
    for( var i = 0; i < ndigit ; i=i+1 ) {
        v2 = int( v / 10 );
        r = v - v2 * 10;
        setprop( prop~i, r );
        v = v2;
    }
}

var calcHoursMeter = func(dt) {
    var t = hmHobbs.getValue();
    if( rpmN.getValue() > 100.0 ) {
        t = t + dt;
        hmHobbs.setValue( t );
    }
    setprop("instrumentation/clock/flight-meter-hour", t / 3600);
#    calcDigits( int(t / 3600), "/instrumentation/hobbs-meter/digits", 6);
    var q = hmTach.getValue() + dt * rpmN.getValue() / 2566.0;
    hmTach.setValue( q );
    setprop("instrumentation/clock/tach-meter-hour", q / 3600);
#    calcDigits( int(q / 3600), "/instrumentation/tach-meter/digits", 6);
}

var calcRollSpeed = func(dt) {
	mps = getprop("velocities/uBody-fps") * 0.3048;
	foreach (g; props.globals.getNode("gear").getChildren("gear")) {
		computeRollSpeedforGear(g, mps, dt);
	}
}

var computeRollSpeedforGear = func(g, mps, dt) {
	wow = g.getNode("wow").getValue();
	if( wow ) {
		g.getNode("rollspeed-ms").setValue(mps);
	} else {
		newspeed = 0.90 * g.getNode("rollspeed-ms").getValue();
		g.getNode("rollspeed-ms").setValue(newspeed);
	}
}

var setAdfFrequency = func(digit, n, m) {
        var v = getprop("instrumentation/adf[0]/frequencies/selected-khz-digits" ~ digit);
        if( digit == 2) {
            v = v + 10 * getprop("instrumentation/adf[0]/frequencies/selected-khz-digits3");
            setprop("instrumentation/adf[0]/frequencies/selected-khz-digits3", 0);
        }
        v = math.mod(v + n + m, m);
        setprop("instrumentation/adf[0]/frequencies/selected-khz-digits" ~ digit, v);
        var newFreq = getprop("instrumentation/adf[0]/frequencies/selected-khz-digits0") +
            10*getprop("instrumentation/adf[0]/frequencies/selected-khz-digits1") + 
            100*getprop("instrumentation/adf[0]/frequencies/selected-khz-digits2") + 
            1000*getprop("instrumentation/adf[0]/frequencies/selected-khz-digits3");
        if( newFreq >= 200 and newFreq <= 1800) {
            setprop("instrumentation/adf[0]/frequencies/selected-khz", newFreq);
        }
}

##########################################
# Click Sounds
##########################################

var PlaySound = func (name, timeout=0.1, delay=0) {
    var sound_prop = "/sim/model/c150/sound/" ~ name;

    settimer(func {
        # Play the sound
        setprop(sound_prop, 1);

        # Reset the property after 0.2 seconds so that the sound can be
        # played again.
        settimer(func {
            setprop(sound_prop, 0);
        }, timeout);
    }, delay);
};


var MainSystem = {
    parents: [Updatable],

    reset: func {

    },
    update: func(dt) {

        calcMixture( dt );
        calcEC( dt );
        calcHoursMeter( dt );

        # some sounds are louder if the doors or windows are opened
        ldoorw = 0.0;
        rdoorw = 0.0;
        if( getprop("sim/model/c150/doors/door[0]/position-norm") > 0.0 ) { ldoorw += 1.0; }
        elsif( getprop("sim/model/c150/doors/door[2]/position-norm") > 0.0 ) { ldoorw += 0.5; }
        if( getprop("sim/model/c150/doors/door[1]/position-norm") > 0.0 ) { rdoorw += 1.0; }
        elsif( getprop("sim/model/c150/doors/door[3]/position-norm") > 0.0 ) { rdoorw += 0.5; }
        if( getprop("/velocities/airspeed-kt") > 10.0 )
            setprop("sim/model/c150/doors/doorw", ldoorw + rdoorw);
        else
            setprop("sim/model/c150/doors/doorw", 0);

        if( getprop("/sim/current-view/internal") > 0)
            setprop("sim/model/c150/sound/doorsk", 1.0 + (ldoorw + rdoorw) / 2.0);
        else
            setprop("sim/model/c150/sound/doorsk", 1.0);

        setprop("controls/engines/engine/magnetos", getprop("controls/engines/engine/c150-magnetos"));

        calcRollSpeed(dt);

        calcDigits( getprop("instrumentation/adf[0]/frequencies/selected-khz"), 
            "instrumentation/adf[0]/frequencies/selected-khz-digits", 4);
    },
};

var done_once = 0;

var do_once = func {
    if( ! done_once ) {

        props.setAll("/controls/engines/engine", "mixture-lever", 0);

        settimer(init_doors, 0.7);
        settimer(init_electrical, 1.0);
        var aircraftState = getprop("/sim/aircraft/state") or "";
        if (aircraftState == "cold-and-dark") {
            cold_start();
        }
        if (aircraftState == "hot") {
            hot_start();
        }
        if( string.match(aircraftState, "test*"))
        {
            initPerfTest(aircraftState);
        }
    }
    done_once = 1;
};


var dialog_battery_reload = func {
    reset_battery_and_circuit_breakers();
    gui.popupTip("The battery is now fully charged!");
}

var dialog_hot_start = func {
    gui.popupTip("Press the 's' key to start the engine.");
    hot_start();
}

# reset code ========================================================
var cold_start = func {
	print("cold start");
    voltN.setValue( 0.0 );
	setprop("controls/gear/brake-parking", 1);
	setprop("accelerations/pilot-g", 1.0);
	setprop("controls/engines/engine/primer", 0);
	setprop("controls/engines/engine/primer-pump", 0);
	MixtureLever.setValue(0.0);
	fdmMixture.setValue(0.0);
	rpmN.setValue( 0.0 );
	setprop("controls/engines/engine/c150-magnetos", 0);
	setprop("controls/engines/engine/magnetos", 0);
	setprop("controls/engines/engine/master-alt", 0);
	setprop("controls/engines/engine/master-bat", 0);
	setprop("engines/engine/running", 0);
	setprop("controls/engines/engine/throttle", 0.0);
	setprop("controls/lighting/beacon", 0);
}

var hot_start = func {
	cold_start();
	print("hot start");
	fdmMixture.setValue(1.0);
	MixtureLever.setValue(1.0);
	rpmN.setValue( 700.0 );
	setprop("controls/engines/engine/c150-magnetos", 3);
	setprop("controls/engines/engine/magnetos", 3);
	setprop("controls/engines/engine/master-alt", 1);
	setprop("controls/engines/engine/master-bat", 1);
	setprop("controls/engines/engine/primer", 3);
	setprop("engines/engine/running", 1);
	setprop("controls/engines/engine/throttle", 0.3);
	setprop("controls/lighting/beacon", 1);
}

# main() ============================================================
var crashed = props.globals.getNode("sim/crashed", 1);
var reset = props.globals.getNode("sim/model/c150/reset", 1);

var main_loop = func {

if(getprop("/controls/engines/engine/c150-magnetos") > 3 or getprop("/controls/engines/engine/starter-key") == 1){
var start = 1;
}else{
var start = 0;
}
if(start == 1 and getprop("/systems/electrical/volts") > 10){
        setprop("/controls/engines/engine/starter", 1);
    }else{
        setprop("/controls/engines/engine/starter", 0);
}

    if (reset.getValue()) {
        on_menu_reset();
    } elsif (crashed.getValue()) {
        crash();
    }
    settimer(main_loop, 0.5);
}


var crash = func {
    print("crashed ?");
	cold_start();
    reset.setIntValue(1);
}

var on_menu_reset = func {
	reset.setIntValue(0);
	cold_start();
}

print("c150 initializing...");

var loop = UpdateLoop.new(components: [MainSystem], update_period: 0.1, enable: 1);

setlistener("/sim/signals/fdm-initialized", func {
    print("FDM is initialized...");
    on_menu_reset();
    settimer(main_loop, 1.0);
    settimer(func {NavLights.nav_light_loop();}, 3.0);

    do_once();
});
