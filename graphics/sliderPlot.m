%SliderPlot: For a given set of time-varying data create a figure that has
%a slider that allows the user to go through the time data
%
% USAGE SliderPlot(data)
%
% INPUT data: cell array containing different data sets to plot on the
%           same figure. Each of the element in the array is a vector. The cell array
%           can be of any dimension
%


function SliderPlot(data,title)

numData = length(data);

%Hard coded in for now, so that we can have the same color schemes across
%fish.
colorM(:,1) = [0.11 0.95 0.58];
colorM(:,2) = [0.50 0.34 0.22];

%~Dangerous assumption here-all entries in data have the same number of
%fields.

if(sum(ismember(size(data),1))>0)
    fieldSize = size(data{1});
else
    fieldSize = size(data);%Singular data set
end

hFig = figure('MenuBar', 'none');



set(hFig, 'Position', [502, 302, 1108, 669]);
set(hFig, 'Name', title.dataSet);

hManipPanel = uipanel('Parent', hFig, 'Units', 'Normalized', ...
    'Position', [0.025 0.025 0.95 0.2]);

numDim = sum(size(fieldSize)>0);

%Where we show the plots
hShowImPanel = uipanel('Parent', hFig, 'Units', 'Normalized',...
    'Position', [0.025 0.250 0.95 0.7125]);
hAxes = axes('Parent', hShowImPanel, 'Units', 'Normalized',...
    'Position', [0.025 0.025 0.95 0.95]);
set(hAxes, 'YLim', [0 200]);
for nD = 1:numData
    hL(nD) = line(1:length(data{nD}{1,1}),data{nD}{1,1},'Parent', hAxes, 'Color', colorM(:,nD));
end

legend(hL, {title.dataType{1}, title.dataType{2}});



for nD = 1:numDim
    sliderHandle(nD,:) = createSlider(nD, fieldSize, hManipPanel);
end


    function thisSliderHandle = createSlider(nF, fieldSize, hFig)
  
        hSpace = 0.3;
        vSpace = 0.3;
        thisSliderHandle{1} = uicontrol('Parent', hFig, 'Units', 'Normalized', 'Position', [0.025 0.1+(vSpace)*(nF-1) 0.2 0.2],...
            'Style', 'Text', 'String', ['Var', num2str(nF)]);
        
        thisSliderHandle{2} = uicontrol('Parent', hFig, 'Units', 'Normalized',...
            'Position', [0.025+hSpace,  0.1+(vSpace)*(nF-1),  0.1, 0.15],...
            'Style', 'edit', 'Tag', num2str(nF), 'String', 1, 'Callback', @z_Callback);
        thisSliderHandle{3} = uicontrol('Parent', hFig,'Units', 'Normalized', 'Position', [0.025+(2*hSpace),  0.1+(vSpace)*(nF-1), 0.3, 0.1],...
            'Style', 'slider', 'Min', 1, 'Max', fieldSize(nF), 'SliderStep', [1/fieldSize(nF) 2/fieldSize(nF)], 'Value', 1, 'Tag', num2str(nF),...
            'Callback', @z_Callback);        
   
    end


    function z_Callback(hObject, eventdata)
        tagVal = get(hObject, 'tag'); tagVal = str2num(tagVal);
        
        value = get(hObject, 'Value');
        value = int16(value);
        set(hObject, 'Value', double(value));
        
        %Update shown value
        h = intersect(findobj('Tag', num2str(tagVal)), findobj('Style', 'edit'));
        for i=1:length(h)
            set(h, 'String', num2str(value));
        end
        
        %Get current values of all the entries-do it all here again for
        %transparancy
        
        for nD=1:numDim
           tagVal(nD) = get(sliderHandle{nD,3}, 'Value');
           
        end
        
        %Update plots
        for nD=1:numData
            %NOT GENERAL!!!
            set(hL(nD), 'XData', 1:length(data{nD}{tagVal(1),tagVal(2)}));
            set(hL(nD), 'YData', data{nD}{tagVal(1),tagVal(2)});
        end
    end

end