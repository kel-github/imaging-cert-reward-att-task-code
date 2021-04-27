function [x,y] = check_eyegaze_location(eye_used, el)

% read the gaze coords - firstly check for presence of a new sample update
if Eyelink('NewFloatSampleAvailable') > 0
    % get the sample in the form of an event structure
    evt = Eyelink('NewestFloatSample');
    % get current gaze position from sample
    x = evt.gx(eye_used+1); % +1 as we're accessing MATLAB array
    y = evt.gy(eye_used+1);
    % do we have valid data and is the pupil visible?
    if x~=el.MISSING_DATA && y~=el.MISSING_DATA && evt.pa(eye_used+1)>0

        x = evt.gx(eye_used+1); % +1 as we're accessing MATLAB array
        y = evt.gy(eye_used+1);
        
    else
        x = NaN;
        y = NaN;
        
    end
else
    x = NaN;
    y = NaN;
end
end