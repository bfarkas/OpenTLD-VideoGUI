function journal = tld2dikablis( bb,video_width,video_height )
%TLD2DIKABLIS converts tld data to dikablis journal
%
%   the following columns need to be filled with data:
%
%   idx = framenumber starting with 0
%   timestamp = time in ms since processing started
%   eyeroihoriz,eyeroivert,eyeroizoomx,eyeroizoomy = calibration values
%       that should be set beforehand. maybe let user input those four?
%   blendmode,blendfactor,onlinecalib = 1,128,0
%   eye_valid = 1 if coordinates are not NaN
%   eye_x,eye_y = x,y coordinates of the pupil
%   eye_w,eye_h = width,heigth of the pupil
%   eye_a = area of the pupil (rectangle or circle???)
%   field_x,field_y = x,y coordinates of the pupil in the fieldcam video
%   displaymode,displayeyedetection = 2,1
%   event = arbitrary string
%
%   bb contains the following data:
%   x1,y1 = bottom left corner of rectangle
%   x2,y2 = top right corner of rectangle

    tic; % initilialize time reference
    frames = size(bb,2);
    journal = zeros(frames,20);
    eyeroihoriz = 0;
    eyeroivert  = 0;
    eyeroizoomx = 0;
    eyeroizommy  = 0;
    blendmode  = 1;
    blendfactor  = 128;
    onlinecalib = 0;
    displaymode = 2;
    displayeyedetection = 1; 
    event = 0;
    
    for frame = 1:frames
        % iterate over all frames and fill journal
        idx = frame - 1;
        timestamp = round(toc*1000); % get time in ms
        if isnan(bb(1,frame))
            eye_valid = 0;
            eye_x = 0;
            eye_y = 0;
            eye_w = 0;
            eye_h = 0;
            field_x = 0;
            field_y = 0;
        else
            eye_valid = 1;
            % convert bb coordinates...
            % assuming x and y coordinates are the center of the pupil
            eye_w = bb(3,frame)-bb(1,frame);
            eye_h = bb(4,frame)-bb(2,frame);
            eye_x = bb(1,frame)+0.5*eye_w;
            eye_y = video_height-(bb(2,frame)+0.5*eye_h);
            % no idea how this should work, so assuming eye coordinates
            field_x = eye_x;
            field_y = eye_y;
        end

        % assume journal needs area of ellipse, the dikablis values are a
        % bit off
        eye_a = eye_w*0.5*eye_h*0.5*pi;
        journal(frame,:) = [idx timestamp eyeroihoriz eyeroivert eyeroizoomx eyeroizommy blendmode blendfactor onlinecalib eye_valid eye_x eye_y eye_w eye_h eye_a field_x field_y displaymode displayeyedetection event];
    end    
end

