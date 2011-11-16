function varargout = imadjustgui(varargin)
% IMADJUSTGUI M-file for imadjustgui.fig
%      IMADJUSTGUI, by itself, creates a new IMADJUSTGUI or raises the existing
%      singleton*.
%
%      Copyright (c) 2009  Zhiping XU 
%      School of Computer Science, Fudan University
%      dr.bennix @ gmail.com
% 
%      H = IMADJUSTGUI returns the handle to a new IMADJUSTGUI or the handle to
%      the existing singleton*.
%
%      IMADJUSTGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IMADJUSTGUI.M with the given input arguments.
%
%      IMADJUSTGUI('Property','Value',...) creates a new IMADJUSTGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before imadjustgui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to imadjustgui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help imadjustgui

% Last Modified by GUIDE v2.5 24-Nov-2009 20:53:01

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @imadjustgui_OpeningFcn, ...
                   'gui_OutputFcn',  @imadjustgui_OutputFcn, ...
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


% --- Executes just before imadjustgui is made visible.
function imadjustgui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to imadjustgui (see VARARGIN)

% Choose default command line output for imadjustgui
handles.output = hObject;
handles.low_in =0;
handles.high_in=1;
handles.low_out=0;
handles.high_out=1;
handles.alpha=1;
hanfles.f=[];
handles.newf=[];
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes imadjustgui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = imadjustgui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in btnOpenImage.
function btnOpenImage_Callback(hObject, eventdata, handles)
% hObject    handle to btnOpenImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[filename,pathname] = uigetfile({'*.bmp';'*.jpg';'*.tif';'*.*'},...
'Open Image');
if all(filename~=0)
   set(handles.lbCurFilename,'String',[pathname filename])
   handles.f =importdata([pathname filename]);
   axes(handles.axes1);
   imshow(handles.f);
   set(handles.axes1,'Visible','on');
   axis off
end
guidata(hObject,handles);

function common_imadjust_call(hObject, eventdata, handles)
handles.low_in =get(handles.slLowIn,'Value');
handles.high_in=get(handles.slHighin,'Value');
handles.low_out=get(handles.slLowout,'Value');
handles.high_out=get(handles.slHighout,'Value');
handles.alpha=get(handles.slAlpha,'Value');
handles.newf=imadjust(handles.f, [handles.low_in handles.high_in], [handles.low_out,handles.high_out], handles.alpha);
axes(handles.axes1);
imshow(handles.newf);
 axis off
 guidata(hObject,handles);

% --- Executes on slider movement.
function slLowIn_Callback(hObject, eventdata, handles)
% hObject    handle to slLowIn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
common_imadjust_call(hObject, eventdata, handles)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

% --- Executes during object creation, after setting all properties.
function slLowIn_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slLowIn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function slHighin_Callback(hObject, eventdata, handles)
% hObject    handle to slHighin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
common_imadjust_call(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function slHighin_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slHighin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function slLowout_Callback(hObject, eventdata, handles)
% hObject    handle to slLowout (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
common_imadjust_call(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function slLowout_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slLowout (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function slHighout_Callback(hObject, eventdata, handles)
% hObject    handle to slHighout (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
common_imadjust_call(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function slHighout_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slHighout (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function slAlpha_Callback(hObject, eventdata, handles)
% hObject    handle to slAlpha (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
common_imadjust_call(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function slAlpha_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slAlpha (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
