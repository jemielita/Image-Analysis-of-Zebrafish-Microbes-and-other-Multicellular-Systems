%Parameters for fitting the logistic growth model
function [halfboxsize, alt_fit, tolN, params0, LB, UB, lsqoptions, fitRange] = getFitParameters(adjustFitParam,fitParam)

halfboxsize = 5;  % +/- 2 time points for boxcar standard deviation for logistic growth fit
alt_fit = true;
tolN = 1e-4; %Use default value for tolernace in N for fitting of 1e-4
params0 = []; %Use default value.
LB = [0,0,1,0];
%UB = [inf, inf, max(N), max(t)];
UB = [];
lsqoptions = optimset('lsqnonlin');

fitRange = 'all';

if(adjustFitParam== true)
    %Get all parameters that we've manually set
    userParam = fieldnames(fitParam);
    
    for nF = 1:length(userParam)
        %Compare to list of fit parameters, if the user selection matches one, then update that.
        %If the variable doesn't match anything in this list return an error
        
        switch userParam{nF}
            case 'halfboxsize'
                halfboxsize = getfield(fitParam, userParam{nF});
            case 'alt_fit'
                alt_fit = getfield(fitParam, userParam{nF});
                
            case 'tolN'
                tolN = getfield(fitParam, userParam{nF});
            case 'params0'
                params0 = getfield(fitParam, userParam{nF});
            case 'LB'
                LB = getfield(fitParam, userParam{nF});
            case 'UB'
                UB = getfield(fitParam, userParam{nF});
                
            case 'fitRange'
                fitRange = getfield(fitParam, userParam{nF});
            otherwise
                fprintf(2,'This parameter does not exist!\n');
                return
            
        end
         
    end
    
    
    
end

end