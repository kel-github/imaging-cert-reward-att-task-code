function [ts] = do_visual_events(wh, n, ts, sess, cue, target, ccw, hrz, col_map, ...
                                 shift, contrast, glb_alph, event_fid, event_form)
                             
    % inputs:
    % wh             = window handle
    % ts = structure of timestamps
    % sess           = subject session structure
    % cue            = numeric value indicating what 'draw_stim' should draw. See
    % 'draw_stim' for details
    % target         = does the target go on the left or on the right? 1 = left, 2
    % = right
    % ccw            = 0 or 1 to indicate whether the target should be tilted to
    % the left or to the right
    % hrz            =  0 or 1 - should the distractor be on the horizontal or the
    % cardinal axis?
    % col_map        = 3 (r,g,b) x 2 (n locations) mapping of colours to
    % left vs right, can be -1 when reward = 2
    % shift          = degrees of rotation, for the current case, shift = 45
    % contrast       = a vector of elements of n stim, with contrast values
    % obtained from staircasing
    % glb_alph       = global alpha for masks: goes from 0 (transparent) to 1
    % (opaque) 
    % event_fid      = file identifier for events
    % event_form     = form for informtaion to be printed to event fid
    
    time = sess.time; % timing parameters
    white = sess.config.stim_light;
    grey = sess.config.grey;
    stim_dark = sess.config.stim_dark;
    gabor_id = sess.config.gabor_id;
    gabor_rect = sess.config.gabor_rect;
    
    vc_pwidth = 80; % pen width of value cues
    
    switch cue
        case -1
            cue_colour = white;
        case 0
            cue_colour = stim_dark;
        otherwise
            cue_colour = [[white white white]', [90, 90, 90]'];
    end
    
    value_cue_colour = col_map;    
    
    if sess.eye_on        
       xc = sess.xc;
       yc = sess.yc;
       r = sess.r;        
    end
    
    % Draw the cue display.
    draw_pedestals(wh, 1:2, gabor_rect, 0.5 * get_ppd(), white, grey);
    draw_value_cues(wh, 1:2, value_cue_colour, vc_pwidth, gabor_rect);
    draw_stim(wh, cue, [cue_colour(:,1) cue_colour(:,1)]); % here cue colour is the same value x 2 to make a plain polygon
    [ts.cue(n)] = Screen('Flip', wh);
%    do_trigger(trid, labjack, triggers.cue, ts.cue);
    if sess.eye_on % get eye gaze position
        [x, y] = check_eyegaze_location(eye_used, el); % GET EYEUSED VARIABLE
        check_dist(x, y, xc, yc, r, n, lg_fid);
    end 
    
    % draw the spatial cue display
    draw_pedestals(wh, 1:2, gabor_rect, 0.5 * get_ppd(), white, grey);
    draw_value_cues(wh, 1:2, value_cue_colour, vc_pwidth, gabor_rect);
    draw_stim(wh, cue, cue_colour); 
    [ts.spatial(n)] = Screen('Flip', wh, ts.cue(n)+time.cue);
    % print the value events to file
    fprintf( event_fid, event_form, ts.cue(n), ts.spatial(n) - ts.cue(n), 'value cues' );
    
%    do_trigger(trid, labjack, triggers.cue, ts.cue);
    if sess.eye_on % get eye gaze position
        [x, y] = check_eyegaze_location(eye_used, el); % GET EYEUSED VARIABLE
        check_dist(x, y, xc, yc, r, n, lg_fid);
    end     
    
    % Hold with the fixation signal.
    draw_pedestals(wh, 1:2, gabor_rect, 0.5 * get_ppd(), white, grey);
    draw_value_cues(wh, 1:2, value_cue_colour, vc_pwidth, gabor_rect);
    draw_stim(wh, cue, [cue_colour(:,1) cue_colour(:,1)]);
    [ts.hold(n)] = Screen('Flip', wh, ts.spatial(n)+time.spatial);
    % print the spatial event to file
    fprintf( event_fid, event_form, ts.spatial(n), ts.hold(n) - ts.spatial(n), 'spatial cue' );
    
%    do_trigger(trid, labjack, triggers.hold, ts.hold);
    if sess.eye_on % get eye gaze position
        [x, y] = check_eyegaze_location(eye_used, el); % GET EYEUSED VARIABLE
        check_dist(x, y, xc, yc, r, n, lg_fid);
    end  
    
    % Draw the targets.
    %draw_value_cues(wh, 1:2, value_cue_colour, vc_pwidth);
    draw_targets(wh, gabor_id, gabor_rect, target, (-1)^(~ccw)*shift, ...
                 hrz, contrast);
    draw_stim(wh, cue, [cue_colour(:,1) cue_colour(:,1)]);
    draw_value_cues(wh, 1:2, value_cue_colour, vc_pwidth, gabor_rect); 
    KbQueueFlush;
    KbQueueStart; % start keyboard check queue
    hold_time = time.hold + rand*time.hold_v;
    [ts.target(n)] = Screen('Flip', wh, ts.hold(n)+hold_time);
    
    % Mask the masks.
    draw_stim(wh, cue, [cue_colour(:,1) cue_colour(:,1)]);
    draw_masks(wh, gabor_rect, 0.4*get_ppd(), white, grey, glb_alph);
    draw_value_cues(wh, 1:2, value_cue_colour, vc_pwidth, gabor_rect);
    [ts.mask(n)] = Screen('Flip', wh, ts.target(n)+time.target);
    % write targets to event file
    fprintf( event_fid, event_form, ts.target(n), ts.mask(n) - ts.target(n), 'target' );
    %        do_trigger(trid, labjack, triggers.mask, ts.mask);
    
    % Fixation 
    draw_pedestals(wh, 1:2, gabor_rect, 0.5 * get_ppd(), white, grey);
    draw_value_cues(wh, 1:2, value_cue_colour, vc_pwidth, gabor_rect);
    draw_stim(wh, cue, [cue_colour(:,1) cue_colour(:,1)]);
    [ts.pending(n)] = Screen('Flip', wh, ts.mask(n)+time.mask);    
end
    
    
    
    