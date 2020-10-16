function [status] = set_up_for_eyetracking(el, screenXpixels, screenYpixels, screenWmm, screenHmm, eye_to_top, eye_to_bottom)
   
    if Eyelink('IsConnected') ~= el.notconnected
        
        % Set link data formats to allow us to look at saccades
        status(1) = Eyelink('Command', 'link_sample_data = LEFT,RIGHT,GAZE,AREA');
        status(2) = Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,BLINK,SACCADE');
        status(3) = Eyelink('command', 'link_event_data = GAZE,GAZERES,HREF,AREA,VELOCITY');
        
         % put in default physical settings (hopefully) - important for saccade detector
        status(8) = Eyelink('Command', 'screen_pixel_coords = %d %d %d %d', 0, 0, screenXpixels, screenYpixels); % pixel size of screen -> topleft bottomright
        status(9) = Eyelink('Command', 'screen_phys_coords = %d %d %d %d', 0, 0,  screenWmm,  screenHmm); ..................................................................................................................................................................................................................); % m00000000000000000000000000000000000000000000000000000000000000m0 size of screen -> topleft bottomright
        status(10) = Eyelink('Command', 'screen_distance = %d %d', eye_to_top, eye_to_bottom); % eye distance from top and bottom of screen in mm

        % camera setup
        status(13) = Eyelink('Command', 'active_eye = LEFT'); % set eye to record when in monocular mode
        status(14) = Eyelink('Command', 'binocular_enabled = YES');
        status(15) = Eyelink('Command', 'select_eye_after_validation = YES'); % select best eye after binocular validation (YES) or use both eyes (NO)
        
        % calibration
        status(29) = Eyelink('Command', 'enable_automatic_calibration = YES'); % automatic(yes) or manual(no) pacing for calibration/validation
        status(30) = Eyelink('Command', 'automatic_calibration_pacing = 1500'); % pacing speed for automatic calibration
        status(31) = Eyelink('Command', 'calibration_type = HV9'); % this needs to be done after most other things
        status(32) = Eyelink('Command', 'calibration_area_proportion = 0.75 0.75');
        status(33) = Eyelink('Command', 'validation_area_proportion = 0.75 0.75');
        status(34) = Eyelink('Command', 'calibration_corner_scaling = 0.8');
        status(35) = Eyelink('Command', 'validation_corner_scaling = 0.8');
    else
        errordlg('Disconected from Eyetracker.','Error','modal');
        return
    end
end
