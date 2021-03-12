function [valid, response, ts] = ...
    do_trial(wh, sess, task, cue, target, ccw, hrz, col_map, ...
             shift, contrast, glb_alph, reward, current_reward, train)
   
    % inputs:
    % wh             = window handle
    % sess           = subject session structure
    % task           = task structure containing response assignments
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
    % reward         = reward case, 0 = low reward, 1 = high reward, 9 = none
    % current_reward = current accrued reward value 
    % train          = provide reward, or initital learning feedback? 0 for
    % reward, 1 for initial learning, 2 for uninformative
    
    % Begin the trial presentation
    
%    trid = sess.trid; % trigger log filename - The next few lines are a
%    previous iteration
%    triggers = sess.triggers; % trigger numbers
%    labjack = sess.labjack; %trigger port
%     EEG

    time = sess.time; % timing parameters
    white = sess.config.stim_light;
    grey = sess.config.grey;
    black = sess.config.black;
    stim_dark = sess.config.stim_dark;
    gabor_id = sess.config.gabor_id;
    gabor_rect = sess.config.gabor_rect;
    
    vc_pwidth = 20; % pen width of value cues
    
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
        eyetrack = sess.eyetrack;
        % Start the eyetracker before each trial.
        Eyelink('StartRecording');
        Eyelink('Message', 'SYNCTIME');
        % Time since tracker start.
        eyetrack.start = Eyelink('TrackerTime');
        % Difference between PC and tracker time.
        eyetrack.offset = Eyelink('TimeOffset');
        Eyelink('Message', 'TRIALID %d', trial.trial_num);

        % Send interest areas (you can do this offline too!)
        Eyelink('Message', '!V IAREA RECTANGLE %d %d %d %d %d %s', 1, ...
                fixation_eye_box(1), fixation_eye_box(2), ...
                fixation_eye_box(3), fixation_eye_box(4), 'fix');
    end


    % Draw the fixation for baseline.
    draw_pedestals(wh, 1:2, gabor_rect, 0.5 * get_ppd(), white, grey);
    if cue > -1
    draw_stim(wh, 1, [[white, white, white]',[white, white, white]']);
    end
    draw_stim(wh, 0, stim_dark);
    [ts.baseline] = Screen('Flip', wh);
%     do_trigger(trid, labjack, triggers.baseline, ts.baseline);
    if sess.eye_on
        Eyelink('Message', 'Baseline');
    end    

    % Draw the cue display.
    draw_pedestals(wh, 1:2, gabor_rect, 0.5 * get_ppd(), white, grey);
    draw_value_cues(wh, 1:2, value_cue_colour, vc_pwidth, gabor_rect);
    draw_stim(wh, cue, [cue_colour(:,1) cue_colour(:,1)]); % here cue colour is the same value x 2 to make a plain polygon
    [ts.cue] = Screen('Flip', wh, ts.baseline+time.baseline);
%    do_trigger(trid, labjack, triggers.cue, ts.cue);
    if sess.eye_on
        Eyelink('Message', 'Cue');
    end
    
    % draw the spatial cue display
    draw_pedestals(wh, 1:2, gabor_rect, 0.5 * get_ppd(), white, grey);
    draw_value_cues(wh, 1:2, value_cue_colour, vc_pwidth, gabor_rect);
    draw_stim(wh, cue, cue_colour); 
    [ts.spatial] = Screen('Flip', wh, ts.cue+time.cue);
%    do_trigger(trid, labjack, triggers.cue, ts.cue);
    if sess.eye_on
        Eyelink('Message', 'Cue');
    end
    
    % Hold with the fixation signal.
    draw_pedestals(wh, 1:2, gabor_rect, 0.5 * get_ppd(), white, grey);
    draw_value_cues(wh, 1:2, value_cue_colour, vc_pwidth, gabor_rect);
    draw_stim(wh, cue, [cue_colour(:,1) cue_colour(:,1)]);
    [ts.hold] = Screen('Flip', wh, ts.spatial+time.spatial);
%    do_trigger(trid, labjack, triggers.hold, ts.hold);
    if sess.eye_on
        Eyelink('Message', 'Hold');
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
    [ts.target] = Screen('Flip', wh, ts.hold+hold_time);
%    do_trigger(trid, labjack, triggers.target, ts.target);
    
    % Check eye position.
    valid = 1;
    if sess.eye_on
        Eyelink('Message', 'Target');
        evt = Eyelink('NewestFloatSample');
        if evt < 0
            % This is a problem, fail and report.
            sprintf(['ERROR: No eye tracking sample available. ' ...
                     'Aborting trial.\n']);
            valid = 0;
        else
            x = evt.gx(2);
            y = evt.gy(2);
            if x ~= el.MISSING_DATA && y ~= el.MISSING_DATA && ...
               evt.pa(2) > 0
                if any([x, y] < fixation_eye_box([1, 2])) || ...
                   any([x, y] > fixation_eye_box([3, 4]))
                    sprintf(['WARNING: Eye not on fixation. ' ...
                             'Aborting trial.\n']);
                    draw_pedestals(wh, 1:2, gabor_rect, 0.5 * get_ppd(), white, grey);
                    DrawFormattedText(wh, 'Watch the fixation cross!', ...
                                      'Center', 'Center', white, 115);
                    ts.abort = Screen('Flip', wh);
                    draw_stim(wh, 0, stim_dark);
                    ts.end = Screen('Flip', wh, ts.abort+time.abort);
                    valid = 0;
                end
            end
        end 
    end

    if valid
        % Mask the targets.
        draw_stim(wh, cue, [cue_colour(:,1) cue_colour(:,1)]);
        draw_masks(wh, gabor_rect, 0.4*get_ppd(), white, grey, glb_alph);
        draw_value_cues(wh, 1:2, value_cue_colour, vc_pwidth, gabor_rect);
        [ts.mask] = Screen('Flip', wh, ts.target+time.target);
%        do_trigger(trid, labjack, triggers.mask, ts.mask);
        if sess.eye_on
            Eyelink('Message', 'Mask');
        end    

        % Fixation until response.
        draw_pedestals(wh, 1:2, gabor_rect, 0.5 * get_ppd(), white, grey);
        draw_value_cues(wh, 1:2, value_cue_colour, vc_pwidth, gabor_rect);
        draw_stim(wh, cue, [cue_colour(:,1) cue_colour(:,1)]);
        [ts.pending] = Screen('Flip', wh, ts.mask+time.mask);
        if sess.eye_on
            Eyelink('Message', 'Pending');
        end    
        key_is_down = 0;
        while ~key_is_down
            [key_is_down, first_press] = KbQueueCheck;
        end
        KbQueueStop;
        if first_press(task.responses(1)) > 0 && ...
           first_press(task.responses(2)) > 0
            response.ccw = first_press(task.responses(2)) < ...
                           first_press(task.responses(1));
            ts.response = min(first_press(task.responses));
        else
            response.ccw = first_press(task.responses(2)) > 0;
            ts.response = max(first_press(task.responses));
        end
        response.rt = ts.response - ts.target;
%        do_trigger(trid, labjack, triggers.response, ts.response);
        if sess.eye_on
            Eyelink('Message', 'Response');
        end    

        response.correct = response.ccw == ccw;
        if response.correct
            % Calculate reward based on RT.
            rt0 = sess.reward_max_bonus_rt;
            rt1 = sess.reward_base_rt;
            reward_frac = (response.rt - rt0) / (rt1 - rt0);
            reward_frac(reward_frac < 0) = 0.0;
            reward_frac(reward_frac > 1.0) = 1.0;
            reward_frac = 1.0 - reward_frac;
            switch reward
                case 0
                    response.reward_value = ...
                        round(sess.reward_base_low + sess.reward_bonus_low * reward_frac);
                case 1
                    response.reward_value = ...
                        round(sess.reward_base + sess.reward_bonus * reward_frac);
                case 2
                    response.reward_value = 0;
                case 9
                    response.reward_value = 0;
            end 
        else
            response.reward_value = 0;
        end
%         

        if sess.eye_on
            Eyelink('Message', 'Reward');
        end
        if ~any(train)
            if reward == 9
               % Fixation instead of reward
                draw_pedestals(wh, 1:2, gabor_rect, 0.5 * get_ppd(), white, grey);
                draw_value_cues(wh, 1:2, value_cue_colour, vc_pwidth, gabor_rect);
                draw_stim(wh, cue, [cue_colour(:,1) cue_colour(:,1)]);
                [ts.reward] = Screen('Flip', wh);
            else
                [ts.reward] = animate_reward(wh, sess, response, current_reward);
            end
        else 
            [ts.reward] = provide_feedback(wh, sess, response, train);
        end
%        do_trigger(trid, labjack, triggers.reward, ts.reward);
        
        % Display fixation.
        draw_pedestals(wh, 1:2, gabor_rect, 0.5*get_ppd(), white, grey);
        draw_stim(wh, 0, stim_dark);
        ts.end = Screen('Flip', wh, ts.reward+time.reward);
    else
        response.ccw = -1;
        response.correct = -1;
        response.rt = -1;
        response.reward_value = -1;
        ts.mask = -1;
        ts.pending = -1;
        ts.response = -1;
        ts.reward = -1;
    end % if valid
    
end
