function varargout = VideoGui(varargin)
% VIDEOGUI MATLAB code for VideoGui.fig
%      VIDEOGUI, by itself, creates a new VIDEOGUI or raises the existing
%      singleton*.
%
%      H = VIDEOGUI returns the handle to a new VIDEOGUI or the handle to
%      the existing singleton*.
%
%      VIDEOGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in VIDEOGUI.M with the given input arguments.
%
%      VIDEOGUI('Property','Value',...) creates a new VIDEOGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before VideoGui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to VideoGui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help VideoGui

% Last Modified by GUIDE v2.5 07-Aug-2011 01:39:20

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @VideoGui_OpeningFcn, ...
                   'gui_OutputFcn',  @VideoGui_OutputFcn, ...
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

videoposition = 0;
videoframes = 0;



% --- Executes just before VideoGui is made visible.
function VideoGui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to VideoGui (see VARARGIN)

% begin tld init code
global opt;

addpath(genpath('.')); %init_workspace; 

opt.source          = struct('videofile',1,'camera',0,'input','_input/','bb0',[]); % videofile/camera/directory swith, directory_name, initial_bounding_box (if empty, it will be selected by the user)
opt.savepath        = '_output/'; mkdir(opt.savepath); % output directory that will contain bounding boxes + confidence
opt.savefilename    = '/tld.txt';

min_win             = 24; % minimal size of the object's bounding box in the scanning grid, it may significantly influence speed of TLD, set it to minimal size of the object
patchsize           = [15 15]; % size of normalized patch in the object detector, larger sizes increase discriminability, must be square
fliplr              = 0; % if set to one, the model automatically learns mirrored versions of the object
maxbbox             = 1; % fraction of evaluated bounding boxes in every frame, maxbox = 0 means detector is truned off, if you don't care about speed set it to 1
update_detector     = 1; % online learning on/off, of 0 detector is trained only in the first frame and then remains fixed
opt.plot            = struct('pex',1,'nex',1,'dt',1,'confidence',1,'target',0,'replace',0,'drawoutput',3,'draw',0,'pts',0,'help', 0,'patch_rescale',1,'save',0); 

% Do-not-change -----------------------------------------------------------

opt.model           = struct('min_win',min_win,'patchsize',patchsize,'fliplr',fliplr,'ncc_thesame',0.95,'valid',0.5,'num_trees',10,'num_features',13,'thr_fern',0.5,'thr_nn',0.65,'thr_nn_valid',0.7);
opt.p_par_init      = struct('num_closest',10,'num_warps',20,'noise',5,'angle',20,'shift',0.02,'scale',0.02); % synthesis of positive examples during initialization
opt.p_par_update    = struct('num_closest',10,'num_warps',10,'noise',5,'angle',10,'shift',0.02,'scale',0.02); % synthesis of positive examples during update
opt.n_par           = struct('overlap',0.2,'num_patches',100); % negative examples initialization/update
opt.tracker         = struct('occlusion',10);
opt.control         = struct('maxbbox',maxbbox,'update_detector',update_detector,'drop_img',1,'repeat',1);

% end tld init code

% Choose default command line output for VideoGui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

global processing;
global pausedframe;
processing = 0;
pausedframe = 0;

% UIWAIT makes VideoGui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = VideoGui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in setlearninpoint.
function setlearninpoint_Callback(hObject, eventdata, handles)
% hObject    handle to setlearninpoint (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global firstlearnframe;
    global videoframes;
    firstlearnframe = floor(get(handles.frameslider,'Value')*videoframes);
    if firstlearnframe == 0
        firstlearnframe = 1;
    end

% --- Executes on slider movement.
function frameslider_Callback(hObject, eventdata, handles)
% hObject    handle to frameslider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
    global videoposition;
    global videoframes;
    global opt;
    currentposition = get(hObject,'Value');
    videoposition = floor(currentposition*videoframes);
    if videoposition == 0
        videoposition = 1;
    end
    set(handles.framecounter,'String',num2str(videoposition));
    image(read(opt.source.vidobj, videoposition),'Parent',handles.videowindow);


% --- Executes during object creation, after setting all properties.
function frameslider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to frameslider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in setlearnoutpoint.
function setlearnoutpoint_Callback(hObject, eventdata, handles)
% hObject    handle to setlearnoutpoint (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global lastlearnframe;
    global videoframes;
    lastlearnframe = floor(get(handles.frameslider,'Value')*videoframes);

% --- Executes on button press in openfilebutton.
function openfilebutton_Callback(hObject, eventdata, handles)
% hObject    handle to openfilebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global videoframes;
    global opt;
    [videofile,videopath]=uigetfile('*.*','Choose a Videofile');
    opt.source.vidobj = VideoReader(strcat(videopath,videofile));
    videoframes = opt.source.vidobj.NumberOfFrames;
    opt.source.idx = 1:videoframes;
    set(handles.framecounter,'String','1');
    set(handles.frameslider,'Enable','on');
    %axes(handles.videowindow);
    image(read(opt.source.vidobj, 1),'Parent',handles.videowindow);


% --- Executes on button press in startlearningbutton.
function startlearningbutton_Callback(hObject, eventdata, handles)
% hObject    handle to startlearningbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global tld;
    global opt;
    global firstlearnframe;
    global lastlearnframe;    
    %axes(handles.videowindow);
    set(handles.frameslider,'Enable','inactive');
    set(handles.statuslabel,'String','learning...');
    while 1
        source = tldInitFirstFrame(tld,opt.source,firstlearnframe,opt.model.min_win); % get initial bounding box, return 'empty' if bounding box is too small
        if ~isempty(source), opt.source = source; break; end % check size
    end
    tld = tldInit(opt,[]); % train initial detector and initialize the 'tld' structure
    set(gcf,'CurrentAxes',handles.videowindow);
    tld = tldDisplay(0,tld); % initialize display
    
    % smallest first frame is frame no 2
    if firstlearnframe < 2
        firstlearnframe = 2;
    end
    
    for i = firstlearnframe:lastlearnframe % for every frame
    
        tld = tldProcessFrame(tld,i); % process frame i
        disp(['learned frame no ', num2str(i)]);
        set(gcf,'CurrentAxes',handles.videowindow);
        %tic;
        tldDisplay(1,tld,i); % display results on frame i
    end
    set(handles.startlearningbutton,'Enable','inactive');
    set(handles.statuslabel,'String','done learning');
    

% --- Executes on button press in startprocessing.
function startprocessing_Callback(hObject, eventdata, handles)
% hObject    handle to startprocessing (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global tld;
    global opt;
    global pausedframe;
    global killed;
    killed = 0;
    set(handles.frameslider,'Enable','inactive');
    set(handles.statuslabel,'String','processing...');
    set(gcf,'CurrentAxes',handles.videowindow);
    if pausedframe > 0
        startingframe = pausedframe;
    else
        startingframe = 2;
    end
    for i = startingframe:length(tld.source.idx) % for every frame
        
        tld = tldProcessFrame(tld,i); % process frame i
        disp(['processed frame no ', num2str(i)]);
        pausedframe = i;
        tldDisplay(1,tld,i); % display results on frame i
        if killed == 1
            break;
        end
    end
    bb = tld.bb; conf = tld.conf; % return results
    dlmwrite([opt.savepath opt.savefilename],[bb; conf]');
    disp(['Results saved to ',opt.savepath,opt.savefilename]);
    if killed == 1
        set(handles.statuslabel,'String','killed');
    else    
        set(handles.statuslabel,'String','done processing');
    end
    killed = 0;


% --- Executes on button press in killswitch.
function killswitch_Callback(hObject, eventdata, handles)
% hObject    handle to killswitch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global killed;
    killed = 1;
    


% --- Executes on button press in savebutton.
function savebutton_Callback(hObject, eventdata, handles)
% hObject    handle to savebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global opt;
    [filename,path]=uiputfile('*.txt','Save Output as');
    opt.savepath = path;
    opt.savefilename = filename;


% --- Executes on key press with focus on figure1 and none of its controls.
function figure1_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    global videoposition;
    global videoframes;
    global opt;
    switch eventdata.Key
        case 'leftarrow'
            videoposition = videoposition - 1;
            if videoposition == 0
                videoposition = 1;
            end
            set(handles.frameslider,'Value',videoposition/videoframes);
            set(handles.framecounter,'String',num2str(videoposition));
            image(read(opt.source.vidobj, videoposition),'Parent',handles.videowindow);
        case 'rightarrow'
            videoposition = videoposition + 1;
            if videoposition >= videoframes
                videoposition = videoframes;
            end
            set(handles.frameslider,'Value',videoposition/videoframes);
            set(handles.framecounter,'String',num2str(videoposition));
            image(read(opt.source.vidobj, videoposition),'Parent',handles.videowindow);
    end
    
% --- Executes on key press with focus on frameslider and none of its controls.
function frameslider_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to frameslider (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
