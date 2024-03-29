function varargout = packageGUI(varargin)
% PACKAGEGUI M-file for packageGUI.fig
%      PACKAGEGUI, by itself, creates a new PACKAGEGUI or raises the existing
%      singleton*.
%
%      H = PACKAGEGUI returns the handle to a new PACKAGEGUI or the handle to
%      the existing singleton*.
%
%      PACKAGEGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PACKAGEGUI.M with the given input arguments.
%
%      PACKAGEGUI('Property','Value',...) creates a new PACKAGEGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before packageGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to packageGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help packageGUI

% Last Modified by GUIDE v2.5 19-Oct-2011 14:16:02

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @packageGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @packageGUI_OutputFcn, ...
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

% --- Outputs from this function are returned to the command line.
function varargout = packageGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% In case the package GUI has been called without argument
userData = get(handles.figure1, 'UserData');
if (isfield(userData,'startMovieSelectorGUI') && userData.startMovieSelectorGUI)
    movieSelectorGUI('packageName',userData.packageName,'MD',userData.MD);
    delete(handles.figure1)
end

% --- Executes on button press in pushbutton_status.
function pushbutton_status_Callback(~, ~, handles)
userData = get(handles.figure1, 'UserData');

% if movieDataGUI exist
if isfield(userData, 'overviewFig') && ishandle(userData.overviewFig)
    delete(userData.overviewFig)
end

userData.overviewFig = movieDataGUI(userData.MD(userData.id));
set(handles.figure1, 'UserData', userData);

% --- Executes on Save button press or File>Save
function save_Callback(~, ~, handles)
userData = get(handles.figure1, 'UserData');
set(handles.text_saveStatus, 'Visible', 'on')
arrayfun(@save,userData.MD);
pause(.3)
set(handles.text_saveStatus, 'Visible', 'off')


function switchMovie_Callback(hObject, ~, handles)

userData = get(handles.figure1, 'UserData');
nMovies = length(userData.MD);

switch get(hObject,'Tag')
    case 'pushbutton_left'
        newMovieId = userData.id - 1;
    case 'pushbutton_right'
        newMovieId = userData.id + 1;
    case 'popupmenu_movie'
        newMovieId = get(hObject, 'Value');
    otherwise
end

if (newMovieId==userData.id), return; end

% Save previous movie checkboxes
userData.statusM(userData.id).Checked = userfcn_saveCheckbox(handles);

% Set up new movie GUI parameters
userData.id = mod(newMovieId-1,nMovies)+1;
userData.crtPackage = userData.package(userData.id);
set(handles.figure1, 'UserData', userData)
set(handles.popupmenu_movie, 'Value', userData.id)

% Set up GUI
if userData.statusM(userData.id).Visited
   packageGUI_RefreshFcn(handles, 'refresh') 
else
   packageGUI_RefreshFcn(handles, 'initialize') 
end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
userData = get(handles.figure1,'Userdata');
if isfield(userData, 'MD')
    MD = userData.MD;
else
    delete(handles.figure1);
    return;
end

saveRes = questdlg('Do you want to save the current progress?', ...
    'Package Control Panel');

if strcmpi(saveRes,'yes'), arrayfun(@save,userData.MD); end
if strcmpi(saveRes,'cancel'), return; end
delete(handles.figure1);

% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)

userData = get(handles.figure1, 'UserData');

% Find all figures stored in userData and delete them
if isempty(userData), return; end
userDataFields=fieldnames(userData);
isFig = ~cellfun(@isempty,regexp(userDataFields,'Fig$'));
userDataFigs = userDataFields(isFig);
for i=1:numel(userDataFigs)
     figHandles = userData.(userDataFigs{i});
     validFigHandles = figHandles(ishandle(figHandles)&logical(figHandles));     
     delete(validFigHandles);
end

% msgboxGUI used for error reports
if isfield(userData, 'msgboxGUI') && ishandle(userData.msgboxGUI)
   delete(userData.msgboxGUI) 
end

% --- Executes on key press with focus on figure1 and none of its controls.
function figure1_KeyPressFcn(hObject, eventdata, handles)

if strcmp(eventdata.Key, 'return')
    exit_Callback(handles.pushbutton_exit, [], handles);
end
if strcmp(eventdata.Key, 'leftarrow')
    switchMovie_Callback(handles.pushbutton_left, [], handles);
end
if strcmp(eventdata.Key, 'rightarrow')
    switchMovie_Callback(handles.pushbutton_right, [], handles);
end

% --------------------------------------------------------------------
function menu_about_Callback(hObject, eventdata, handles)

status = web(get(hObject,'UserData'), '-browser');
if status
    switch status
        case 1
            msg = 'System default web browser is not found.';
        case 2
            msg = 'System default web browser is found but could not be launched.';
        otherwise
            msg = 'Fail to open browser for unknown reason.';
    end
    warndlg(msg,'Fail to open browser','modal');
end

% --------------------------------------------------------------------
function menu_file_open_Callback(~, ~, handles)
% Call back function of 'New' in menu bar
userData = get(handles.figure1,'Userdata');
if isfield(userData,'MD'), arrayfun(@(x) x.save,userData.MD); end
movieSelectorGUI('packageName',userData.packageName,'MD',userData.MD);
delete(handles.figure1)

% --------------------------------------------------------------------
function exit_Callback(~, ~, handles)

delete(handles.figure1);


% --- Executes on button press in pushbutton_show.
function pushbutton_show_Callback(hObject, ~, handles)

userData = get(handles.figure1, 'UserData');
prop=get(hObject,'Tag');
procID = str2double(prop(length('pushbutton_show_')+1:end));

if isfield(userData, 'resultFig') & ishandle(userData.resultFig)
    delete(userData.resultFig)
end

% Modifications should be added to the resultDisplay methods (should be
% generic!!!!)
if isa(userData.crtPackage,'UTrackPackage')
    userData.resultFig = userData.crtPackage.processes_{procID}.resultDisplay(handles.figure1,procID);
else
    userData.resultFig = userData.crtPackage.processes_{procID}.resultDisplay();
end
    
set(handles.figure1, 'UserData', userData);

% --- Executes on button press in pushbutton_set.
function pushbutton_set_Callback(hObject, ~, handles)

userData = get(handles.figure1, 'UserData');
prop=get(hObject,'Tag');
procID = str2double(prop(length('pushbutton_set_')+1:end));

% Read GUI handle from the associated process static method
crtProc=userData.crtPackage.getProcessClassNames{procID};
crtProcGUI =eval([crtProc '.GUI']);

userData.setFig(procID) = crtProcGUI('mainFig',handles.figure1,procID);
set(handles.figure1, 'UserData', userData);
guidata(hObject,handles);

% --- Executes on button press in checkbox.
function checkbox_Callback(hObject, eventdata, handles)

props=get(hObject,{'Value','Tag'});
procStatus=props{1};
procID = str2double(props{2}(length('checkbox_')+1:end));

userData=get(handles.figure1, 'UserData');
userData.statusM(userData.id).Checked(procID) = procStatus;
set(handles.figure1, 'UserData', userData)


userfcn_checkAllMovies(procID, procStatus, handles);
userfcn_lampSwitch(procID, procStatus, handles);

% --------------------------------------------------------------------
function menu_debug_enter_Callback(hObject, eventdata, handles)

status = get(hObject,'Checked');
if strcmp(status,'on'), newstatus = 'off'; else newstatus='on'; end
set(hObject,'Checked',newstatus);
