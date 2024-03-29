function varargout = costMatRandomDirectedSwitchingMotionLinkGUI(varargin)
% COSTMATRANDOMDIRECTEDSWITCHINGMOTIONLINKGUI M-file for costMatRandomDirectedSwitchingMotionLinkGUI.fig
%      COSTMATRANDOMDIRECTEDSWITCHINGMOTIONLINKGUI, by itself, creates a new COSTMATRANDOMDIRECTEDSWITCHINGMOTIONLINKGUI or raises the existing
%      singleton*.
%
%      H = COSTMATRANDOMDIRECTEDSWITCHINGMOTIONLINKGUI returns the handle to a new COSTMATRANDOMDIRECTEDSWITCHINGMOTIONLINKGUI or the handle to
%      the existing singleton*.
%
%      COSTMATRANDOMDIRECTEDSWITCHINGMOTIONLINKGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in COSTMATRANDOMDIRECTEDSWITCHINGMOTIONLINKGUI.M with the given input arguments.
%
%      COSTMATRANDOMDIRECTEDSWITCHINGMOTIONLINKGUI('Property','Value',...) creates a new COSTMATRANDOMDIRECTEDSWITCHINGMOTIONLINKGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before costMatRandomDirectedSwitchingMotionLinkGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to costMatRandomDirectedSwitchingMotionLinkGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help costMatRandomDirectedSwitchingMotionLinkGUI

% Last Modified by GUIDE v2.5 09-Dec-2011 16:19:54

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @costMatRandomDirectedSwitchingMotionLinkGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @costMatRandomDirectedSwitchingMotionLinkGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before costMatRandomDirectedSwitchingMotionLinkGUI is made visible.
function costMatRandomDirectedSwitchingMotionLinkGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% userData.linkingFig = costMatRandomDirectedSwitchingMotionLinkGUI{procID}('mainFig',
% handles.figure1, procID);
%
% userData.mainFig
% userData.procID
% userData.handles_main
% userData.userData_main
% userData.crtProc
% userData.parameters


[copyright openHelpFile] = userfcn_softwareConfig(handles);
set(handles.text_copyright, 'String', copyright)


userData = get(handles.figure1, 'UserData');
handles.output = hObject;

% Get main figure handle and process id
t = find(strcmp(varargin,'mainFig'));
userData.mainFig = varargin{t+1};
userData.procID = varargin{t+2};
userData.handles_main = guidata(userData.mainFig);
userData.userData_main = get(userData.handles_main.figure1, 'UserData');
userData.crtProc = userData.userData_main.crtProc;

u = get(userData.handles_main.popupmenu_linking, 'UserData');
userData.parameters = u{userData.procID};
parameters = userData.parameters;

% Parameter Setup
set(handles.checkbox_linearMotion, 'Value', logical(parameters.linearMotion));
checkbox_linearMotion_Callback(hObject, eventdata, handles)
set(handles.checkbox_immediateDirectionReversal, 'Value', parameters.linearMotion==2);
set(handles.edit_lower, 'String', num2str(parameters.minSearchRadius))
set(handles.edit_upper, 'String', num2str(parameters.maxSearchRadius))
set(handles.edit_brownStdMult, 'String', num2str(parameters.brownStdMult))
set(handles.checkbox_useLocalDensity, 'Value', parameters.useLocalDensity)
set(handles.edit_nnWindow, 'String', num2str(parameters.nnWindow))

if isempty(parameters.diagnostics) || (length(parameters.diagnostics) == 1 && parameters.diagnostics == 0)
    set(handles.checkbox_diagnostics, 'Value', 0);
    set(get(handles.uipanel_diagnostics,'Children'),'Enable','off');
else
    set(handles.checkbox_diagnostics, 'Value', 1);
    for i = 1:min(3,length(parameters.diagnostics))
        set(handles.(['edit_diag_' num2str(i)]),...
            'String',num2str(parameters.diagnostics(i)));
    end
end


% Get icon infomation
userData.questIconData = userData.userData_main.questIconData;
userData.colormap = userData.userData_main.colormap;

% ----------------------Set up help icon------------------------

% Set up help icon
set(hObject,'colormap',userData.colormap);
% Set up package help. Package icon is tagged as '0'
set(handles.figure1,'CurrentAxes',handles.axes_help);
Img = image(userData.questIconData); 
set(gca, 'XLim',get(Img,'XData'),'YLim',get(Img,'YData'),...
    'visible','off','YDir','reverse');
set(Img,'ButtonDownFcn',@icon_ButtonDownFcn);
if openHelpFile
    set(Img, 'UserData', struct('class', mfilename))
else
    set(Img, 'UserData', 'Please refer to help file.')
end


set(handles.figure1, 'UserData', userData)
% Update handles structure
guidata(hObject, handles);



% UIWAIT makes costMatRandomDirectedSwitchingMotionLinkGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = costMatRandomDirectedSwitchingMotionLinkGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton_cancel.
function pushbutton_cancel_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
delete(handles.figure1)


% --- Executes on button press in pushbutton_done.
function pushbutton_done_Callback(hObject, eventdata, handles)

userData = get(handles.figure1, 'UserData');
lower = str2double(get(handles.edit_lower, 'String'));
upper = str2double(get(handles.edit_upper, 'String'));
brownStdMult = str2double(get(handles.edit_brownStdMult, 'String'));
nnWindow = str2double(get(handles.edit_nnWindow, 'String'));
diagnostics{1} = get(handles.edit_diag_1, 'String');
diagnostics{2} = get(handles.edit_diag_2, 'String');
diagnostics{3} = get(handles.edit_diag_3, 'String');

% lower
isPosScalar = @(x) isscalar(x) && ~isnan(x) && x>=0;
if ~isPosScalar(lower)
    errordlg('Please provide a valid value to parameter "Lower Bound".','Error','modal')
    return
end

% Upper
if ~isPosScalar(upper)
    errordlg('Please provide a valid value to parameter "Upper Bound".','Error','modal')
    return
elseif upper < lower
    errordlg('"Upper Bound" should be larger than "Lower Bound".','Error','modal')
    return
end

% brownStdMult
if ~isPosScalar(brownStdMult)
    errordlg('Please provide a valid value to parameter "Multiplication Factor for Search Radius Calculation".','Error','modal')
    return
end

% nnWindow
if ~isPosScalar(nnWindow)
    errordlg('Please provide a valid value to parameter "Number of Frames for Nearest Neighbor Distance Calculation".','Error','modal')
    return
end

% Set Parameters
parameters = userData.parameters;

parameters.linearMotion = get(handles.checkbox_linearMotion, 'Value')+...
    get(handles.checkbox_immediateDirectionReversal,'Value');
parameters.minSearchRadius = lower;
parameters.maxSearchRadius = upper;
parameters.brownStdMult = brownStdMult;
parameters.useLocalDensity = get(handles.checkbox_useLocalDensity, 'Value');
parameters.nnWindow = nnWindow;


% Set diagnostics parameters
if get(handles.checkbox_diagnostics, 'Value')
    
    if all(cellfun(@isempty, diagnostics))
        errordlg('Please provide 1 or more than 1 (maximum 3) "Frame Numbers to Plot Histograms" in the text boxes.','Error','modal')
        return
    end
    
    validDiagnostics = str2double(diagnostics(~cellfun(@isempty, diagnostics)));
    nFrames= userData.crtProc.owner_.nFrames_;
    if any(isnan(validDiagnostics) | validDiagnostics<2 | validDiagnostics>nFrames-1)
        errordlg('Please provide a valid value to parameter "Frame Numbers to Plot Histograms". Note: the first or last frame of a movie is invalid.','Error','modal')
        return
    end
    parameters.diagnostics =validDiagnostics;
else
    parameters.diagnostics = [];      
end


u = get(userData.handles_main.popupmenu_linking, 'UserData');
u{userData.procID} = parameters;

set(userData.handles_main.popupmenu_linking, 'UserData', u)

% set linearMotion to gap closing cost function "costMatLinearMotionCloseGaps2"
u_gapclosing = get(userData.handles_main.popupmenu_gapclosing, 'UserData');
gapclosingParameters = u_gapclosing{userData.procID};

% Check consistency of search radius parameters with gap closing
checkMinSearchRadius=(gapclosingParameters.minSearchRadius~=lower);
checkMaxSearchRadius=(gapclosingParameters.maxSearchRadius~=upper);
if checkMinSearchRadius || checkMaxSearchRadius
    modifyGapClosingParameters=questdlg('Do you want to use the search radius bounds for the gap closing?',...
        'Modified search radius parameters','Yes','No','Yes');
    if strcmp(modifyGapClosingParameters,'Yes')
        gapclosingParameters.minSearchRadius=lower;
        gapclosingParameters.maxSearchRadius=upper;
    end
end

% Check consistency of search radius parameters with gap closing
checkNewLinearMotion=(gapclosingParameters.linearMotion~=parameters.linearMotion);
checkDirectedMotion = parameters.linearMotion~=0;
gapclosingParameters.linearMotion=parameters.linearMotion;
if checkNewLinearMotion && checkDirectedMotion
    modifyGapClosingParameters=questdlg('Do you want to use the default directed motion parameters for the gap closing?',...
        'Modified linear motion parameters','Yes','No','Yes');
    if strcmp(modifyGapClosingParameters,'Yes')
        if parameters.linearMotion==1
            gapclosingParameters.linStdMult(1)=1;
            gapclosingParameters.linScaling(1)=1;
        else
            gapclosingParameters.linStdMult(1)=3;
            gapclosingParameters.linScaling(1)=.5;
        end
    end
end

u_gapclosing{userData.procID} = gapclosingParameters;
set(userData.handles_main.popupmenu_gapclosing, 'UserData', u_gapclosing)
    
set(handles.figure1, 'UserData', userData);
guidata(hObject,handles);
delete(handles.figure1);

% --- Executes on button press in checkbox_diagnostics.
function checkbox_diagnostics_Callback(hObject, eventdata, handles)

if get(hObject, 'Value'),
    set(get(handles.uipanel_diagnostics,'Children'),'Enable','on');
else
    set(get(handles.uipanel_diagnostics,'Children'),'Enable','off');
end

% --- Executes on key press with focus on figure1 and none of its controls.
function figure1_KeyPressFcn(hObject, eventdata, handles)

if strcmp(eventdata.Key, 'return')
    pushbutton_done_Callback(handles.pushbutton_done, [], handles);
end

% --- Executes on button press in checkbox_linearMotion.
function checkbox_linearMotion_Callback(hObject, eventdata, handles)

if get(handles.checkbox_linearMotion,'Value')
    set(handles.checkbox_immediateDirectionReversal,'Enable','on');
else
    set(handles.checkbox_immediateDirectionReversal,'Enable','off','Value',0);
end
