function [] = run_incentive_value_instruction(wh, reward_cond, col_map, sess)
% show the participant the incentive value disc and the reward
% probabilities

    % inputs:
    % wh = window handle
    % reward_cond = learning about high or low reward?
    % col_map = possible ring colours
    % sess = subject session structure
        
    white = sess.config.stim_light;
    grey = sess.config.grey;
    black = sess.config.black;
    stim_dark = sess.config.stim_dark;
    gabor_id = sess.config.gabor_id;
    gabor_rect = sess.config.gabor_rect;
    value_cue_colour = col_map;
    vc_pwidth = 20; % pen width of value cues
    % Draw the cue display.
    draw_pedestals(wh, 1:2, gabor_rect, 0.5 * get_ppd(), white, grey);
    draw_value_cues(wh, 1:2, value_cue_colour, vc_pwidth, gabor_rect);
   
    % sort numbers
    reward_data = [sess.reward_base, sess.reward_base+sess.reward_bonus; ...
                   sess.reward_base_low, sess.reward_base_low + sess.reward_bonus_low];
    
    reward_instruct = [reward_data(reward_cond, :)];
               
    Screen('TextStyle', wh, 1);
    Screen('TextSize', wh, 30);
    instructions = ...
        sprintf(['When the target appears in a ring this\n', ...
        'colour, then you can score %d to %d points\n', ...
        'most of the time\n\n',...
        '(You will score no points\n',...
        'a little bit of the time)\n\n'...
        'The faster you respond, the more of the points\n'...
        'you can get\n',...
        'Press a key to continue.\n\n'], reward_instruct);
    
    WaitSecs(0.5);
    DrawFormattedText(wh, instructions, 'Center', [], white, 115);
    Screen('Flip', wh);
    
    start_ts = KbWait;
    WaitSecs(0.5);
    


end