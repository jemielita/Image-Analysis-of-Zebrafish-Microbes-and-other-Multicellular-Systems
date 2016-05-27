%% Very specific script for collecting the coarse correlation length of the gut motility of ret vs wt
% Assumes fall2015Data has already been loaded
% Probably won't be useful in the future

params_8_19_15 = gutMotilityAnalysisCollector;
boolSelectorRet = fall2015Data(1).FishType(3,:)&fall2015Data(1).BoolsNaN;
boolSelectorWT = fall2015Data(1).FishType(1,:)&fall2015Data(1).BoolsNaN;
retCorrs8_19 = params_8_19_15(boolSelectorRet,8);
wtCorrs8_19 = params_8_19_15(boolSelectorWT,8);

params_8_20_15 = gutMotilityAnalysisCollector;
boolSelectorRet = fall2015Data(2).FishType(3,:)&fall2015Data(2).BoolsNaN;
boolSelectorWT = fall2015Data(2).FishType(1,:)&fall2015Data(2).BoolsNaN;
retCorrs8_20 = params_8_20_15(boolSelectorRet,8);
wtCorrs8_20 = params_8_20_15(boolSelectorWT,8);

params_8_21_15 = gutMotilityAnalysisCollector;
boolSelectorRet = fall2015Data(3).FishType(3,:)&fall2015Data(3).BoolsNaN;
boolSelectorWT = fall2015Data(3).FishType(1,:)&fall2015Data(3).BoolsNaN;
retCorrs8_21 = params_8_21_15(boolSelectorRet,8);
wtCorrs8_21 = params_8_21_15(boolSelectorWT,8);

%% IMPORTANT: MANUALLY ADD NANS TO VECTORS TO MAKE THEM THE SAME SIZE
wtCorrs8_19 = [wtCorrs8_19',NaN,NaN];
wtCorrs8_20 = [wtCorrs8_20',NaN,NaN];
wtCorrs8_21 = [wtCorrs8_21',NaN,NaN];
retCorrs8_19 = retCorrs8_19';
retCorrs8_20 = [retCorrs8_20',NaN,NaN];
retCorrs8_21 = [retCorrs8_21',NaN,NaN,NaN];

%% Plot
colorWheelBorder = [ [0, 0, 0.4]; [0, 0.3, 0]; [0.4, 0, 0] ];
colorWheelFill = [ [0.6, 0.4, 0.9]; [0.4, 0.95, 0.6]; [0.9, 0.6, 0.4] ];
theTitle = 'WT vs Ret Correlation Lengths (coarse measure)';
groupee = { '5WT', '5Ret', '6WT', '6Ret', '7WT', '7Ret' };
fishOrderedByDay = [wtCorrs8_19; retCorrs8_19;...
                    wtCorrs8_20; retCorrs8_20;...
                    wtCorrs8_21; retCorrs8_21];
colorWheelO = colorWheelBorder( [ 1, 3 ], : );
colorWheelF = colorWheelFill( [ 1, 3 ], : );
scatterBox( fishOrderedByDay', {groupee, colorWheelO, colorWheelF});
axis auto;
title( 'Coarse Gut Motility Correlation Lengths', 'FontSize', 25, 'interpreter','none' );
ylabel( 'Marker Distance', 'FontSize', 30 );
set(gca,'fontsize',20);