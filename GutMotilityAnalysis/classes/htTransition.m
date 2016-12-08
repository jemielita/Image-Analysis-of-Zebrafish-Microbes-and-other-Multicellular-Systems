classdef htTransition
    
    % Define the distinguishing attributes of an object instantiated from this class
    properties
        meanImageIntensityThresh % A float representing what threshold of intensity triggers a transition
    end
    
    % Define the methods for determining criteria for transitioning between states
    methods
        function camTriggerBool = camIsTriggered( obj, curMeanImageIntensity )
            if( curMeanImageIntensity < obj.meanImageIntensityThresh )
                camTriggerBool = true;
            else
                camTriggerBool = false;
            end
        end
    end
end