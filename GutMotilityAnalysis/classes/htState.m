% htState.m
% 
% Background: Our high-throughput lightsheet microscope has a variety of
%             hardware, many pieces of which need to be used for various
%             functions at different times. We computationally model this 
%             as a finite state machine, where we need to define STATES and
%             TRANSITION criteria between states. This class does the 
%             former.
% 
% Description: This class is used to instantiate a state the high- 
%              throughput setup can be in at any time. It can be things 
%              such as which valves are on or off, if the stage is moving, 
%              if the camera is taking a video, etc.
%
% To do: Everything

classdef htState
    
    % Define the distinguishing attributes of an object instantiated from this class
    properties
        
        valve1State % A logical representing the state of valve 1 (on or off)
        valve2State % A logical representing the state of valve 1 (on or off)
        pumpOn % A logical representing the state of the pump (on or off)
        zStart % A float representing the starting z of a light-sheet scan
        zEnd % A float representing the ending z of a light-sheet scan
        deltaZ % A float representing the step sizes of z for a light-sheet scan
        
    end
    
    % Define the methods used to turn valves on or off, control the camera, stages, etc
    methods
        
        % This function will initialize things such as valves, stage position, etc
        function initValves( obj )
            sprintf( 'Sent command to DAQ: Valve 1 is %i, Valve 2 is %i', obj.valve1State, obj.valve2State ) % Here we pretend we are sending a signal to the DAQ
        end
        
        % This function will perform a 3D lightsheet scan between the given z's
        function lightSheetScan( obj )
            sprintf( 'Starting scan at z = %f with a step size dz = %f... ending at z = %f', obj.zStart, obj.deltaZ, obj.zEnd ) % Here we pretend we are sending a signal to the DAQ
        end
        
    end
    
end