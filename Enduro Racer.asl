// Enduro Racer SMS (World) Autosplitter

// Basic format of the script is based on:
// https://raw.githubusercontent.com/Traviktox/Lufia_2_ACAutosplitter/master/Lufia.asl
// which is in turn based on:
// https://github.com/Spiraster/ASLScripts/tree/master/LiveSplit.SMW

// This is a fairly minimal initial effort for my own purposes.
// It is based upon BizHawk 2.10(x64), and tested only on my own setup so far.

state("emuhawk"){}
state("fusion"){}

startup {
	vars.bcdBytes = new Dictionary<string,int> {
		{ "stage", 0x0380 }, // current stage number 1->10
		{ "cumulativeMin", 0x0393 }, // cumulative time as of the end of the last stage
		{ "cumulativeSec", 0x0394 },
		{ "cumulativeMSec", 0x0395 },
		{ "stageStartTime", 0x0350 }, // the value of counterSec when this stage started
		{ "counterSec", 0x0392 }, // number of full seconds left on the clock
	};
	
	vars.memBytes = new Dictionary<string,int> {
		{ "demoMode", 0x0200 }, // 1 if demo
		{ "startFlag", 0x0360 }, // 0 -> 1 when stage starts
		{ "endFlag", 0x0361 }, // 0 -> 1 when stage ends
		{ "screenMode", 0x0110 }, // 02 title, 03 in stage, 04 stage scores, 06 end screen, 07 shop
		{ "counterMSec", 0x0391 }, // counts down repeatedly from 0-60 while running stage
	};
}

init {

	// identify the version of the emulator and where to point at 
    var states = new Dictionary<int, IntPtr> {
		{ 5054464, (IntPtr)0x36F00F45F10 }, //BizHawk 2.10 (x64)
		// This was sucking up my time.  I'm sure the answer is obvious and I'm just missing some fundamental basic.
		// { 4104192, new DeepPointer(modules.First().BaseAddress,0x2A52D8).Deref<IntPtr>(game)+0xC000 }, // Fusion
    };

    IntPtr memoryOffset;
    states.TryGetValue(modules.First().ModuleMemorySize, out memoryOffset);
    if (memoryOffset == default(IntPtr)) {
        throw new Exception("Memory not initialized.");
	}

	// now set up the watched variables from the lists created in startup
	vars.bcdWatchers = new MemoryWatcherList();
	MemoryWatcherList.MemoryWatcherDataChangedEventHandler bcdHandler = (watcher) =>  {
			((IDictionary<String,Object>)current)[watcher.Name] = 10*((byte)watcher.Current >> 4) + ((byte)watcher.Current & 15);
		};
	vars.bcdWatchers.OnWatcherDataChanged += bcdHandler;
	foreach(var pair in vars.bcdBytes) {
		vars.bcdWatchers.Add(new MemoryWatcher<byte>(memoryOffset + pair.Value) { Name = pair.Key });
		((IDictionary<String,Object>)current)[pair.Key] = 0;
	}
	vars.bcdWatchers.UpdateAll(game);
	

	vars.memWatchers = new MemoryWatcherList();
	MemoryWatcherList.MemoryWatcherDataChangedEventHandler memHandler = (watcher) =>  {
			((IDictionary<String,Object>)current)[watcher.Name] = watcher.Current;
		};
	vars.memWatchers.OnWatcherDataChanged += memHandler;
	foreach(var pair in vars.memBytes) {
		vars.memWatchers.Add(new MemoryWatcher<byte>(memoryOffset + pair.Value) { Name = pair.Key });
		((IDictionary<String,Object>)current)[pair.Key] = 0;
	}
	vars.memWatchers.UpdateAll(game);
	
	// Keep track of first loop if running SMS-J 20 stages
	vars.firstLoopTime = new TimeSpan(0);
	
	current.igt = TimeSpan.Zero;
	current.igtCorrected = TimeSpan.Zero;
	current.inRace = false;
}

update {
	vars.bcdWatchers.UpdateAll(game);
	vars.memWatchers.UpdateAll(game);
	
	current.inRace = (current.screenMode == 3 && current.demoMode != 1 && current.startFlag == 1 && current.endFlag != 1);
	current.inLevel = (current.screenMode == 3 && current.demoMode != 1);
	
	if(current.inLevel) {
		// the accumulated time from previous levels + the number of whole seconds elapsed this race according to the counter
		TimeSpan baseIgt = new TimeSpan(0,0,current.cumulativeMin, current.cumulativeSec, current.cumulativeMSec * 10);
		
		// For SMS-J second loop
		if(current.stage > 10)
			baseIgt += vars.firstLoopTime;
		
		baseIgt += TimeSpan.FromSeconds(current.stageStartTime - current.counterSec);
		
		int ms = current.counterMSec * 100 / 60;
		current.igt = baseIgt + TimeSpan.FromMilliseconds(10*(ms%100));
		current.igtCorrected = baseIgt + TimeSpan.FromMilliseconds(10*(100-ms));
		
		if(current.stage <= 10)
			vars.firstLoopTime = current.igt;
	}
	
	// Debug print all of current.
	// print(string.Join(Environment.NewLine,(IDictionary<String,Object>)current));
}

start {
    return current.stage == 1 && current.inRace;
}

reset {
	if(current.screenMode == 2 && timer.CurrentPhase == TimerPhase.Running) { // if the timer is running and we hit the title screen
		timer.CurrentPhase = TimerPhase.Paused;
	}
	
    return current.stage == 1 && current.screenMode == 3 && current.startFlag != 1 && current.demoMode != 1;
}

split {
    return current.inLevel && old.inRace && !current.inRace;
}

gameTime {
	if(current.inRace)
		return current.igtCorrected;
	
	return current.igt;
}

isLoading {
    return true;
}
