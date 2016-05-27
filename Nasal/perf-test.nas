


var startEngine = func {

	print("trying to start the engine...");

	setprop("controls/engines/engine/primer-pump", 0);

	setprop("controls/engines/engine[0]/mixture-lever", 1.0 );
	setprop("controls/engines/engine[0]/mixture", 1.0 );
	setprop("engines/engine[0]/rpm", 2000.0 );
	setprop("controls/engines/engine/magnetos", 3);
	setprop("controls/engines/engine/master-alt", 1);
	setprop("controls/engines/engine/master-bat", 1);
	setprop("controls/flight/aileron", 0.0);
	setprop("controls/engines/engine/primer", 4);
	setprop("engines/engine/running", 1);
	setprop("controls/engines/engine/throttle", 0.7);
	setprop("controls/gear/brake-parking", 0);
	setprop("accelerations/pilot-g", 1.0);

    controls.startEngine(1);
    settimer(func {controls.startEngine(0);}, 5.0);

}

var test1 = func {
    startEngine();
    setprop("/position/altitude-ft", getprop("/position/altitude-ft") + 2000);
#    setprop("/velocities/airspeed-kt", 70.0);
};

var initPerfTest = func(aircraftState) {


    settimer(test1, 2.0);

};