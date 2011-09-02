function journal = tld2dikablis( oldjournal,bb,video_width,video_height )
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
    journal = cell(frames,1);
    
    for frame = 1:frames
        % iterate over all frames and fill journal
        idx = frame - 1;
        %timestamp = round(toc*1000); % get time in ms
        timestamp = oldjournal{1,2}{frame};
        % get constants from old journal
        eyeroihoriz = oldjournal{1,3}{frame};
        eyeroivert  = oldjournal{1,4}{frame};
        eyeroizoomx = oldjournal{1,5}{frame};
        eyeroizommy  = oldjournal{1,6}{frame};
        blendmode  = oldjournal{1,7}{frame};
        blendfactor  = oldjournal{1,8}{frame};
        onlinecalib = oldjournal{1,9}{frame};
        displaymode = oldjournal{1,18}{frame};
        displayeyedetection = oldjournal{1,19}{frame};
        event = oldjournal{1,20}{frame};
        % event causing some cell related trouble atm, leave it blank for
        % now
        % event = ' ';
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
            eye_w = int16(bb(3,frame)-bb(1,frame));
            eye_h = int16(bb(4,frame)-bb(2,frame));
            eye_x = int16(bb(1,frame)+0.5*eye_w);
            eye_y = int16(video_height-(bb(2,frame)+0.5*eye_h));
            % no idea how this should work, so assuming eye coordinates
            field_x = eye_x;
            field_y = eye_y;
        end

        % assume journal needs area of ellipse, the dikablis values are a
        % bit off
        eye_a = int16(eye_w*0.5*eye_h*0.5*pi);
        journal{frame,:} = {idx; timestamp; eyeroihoriz; eyeroivert; eyeroizoomx; eyeroizommy; blendmode; blendfactor; onlinecalib; eye_valid; eye_x; eye_y; eye_w; eye_h; eye_a; field_x; field_y; displaymode; displayeyedetection; event};
    end    
end

