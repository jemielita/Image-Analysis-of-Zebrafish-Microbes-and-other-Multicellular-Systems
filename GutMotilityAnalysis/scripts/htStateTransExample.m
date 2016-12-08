% Script to demonstrate how htState and htTransition work

% Make a state 1 for pump on
htStatePumpOn = htState;
htStatePumpOn.valve1State = true;
htStatePumpOn.valve2State = false;
htStatePumpOn.pumpOn = true;

% Make a state 2 for pump off
htStatePumpOff = htState;
htStatePumpOff.valve1State = false;
htStatePumpOff.valve2State = true;
htStatePumpOff.pumpOn = false;

% Make a state 3 for triggering off of fish
htStateFishTrigger = htState;
% Not sure how to do the looping... most likely in transition... oh right, there was the "Don't use a while(true) loop with case statements, use _ instead"

% Make a state 4 for 3D lightsheet scan
ht3DScan = htState;
ht3DScan.zStart = 1;
ht3DScan.zEnd = 10;
ht3DScan.deltaZ = 1;