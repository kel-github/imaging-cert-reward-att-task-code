function [ts] = provide_feedback(wh, sess, response, condition)

% if condition = 2, then provide noninformative feedback,
% if condition = 1, then provide informative feedback,

    if condition > 1
            colour = sess.config.black;
            ftext  = '.';
    else
        if response.correct
            colour = sess.config.white;
            ftext  = 'Correct :)';
        else
            colour = sess.config.stim_dark;
            ftext  = 'Incorrect :(';
        end
    end

    DrawFormattedText(wh, ftext, 'Center', 'Center', ...
        colour, 115);
    [ts] = Screen('Flip', wh);
    
    % now keep on the screen for the same duration as occurs in the
    % animate_reward function
    n_frames = min(response.reward_value, 20);
    next_ts = ts + 0.25;
    ts_i = 0.3 / n_frames;
    for i = 1:n_frames
            [next_ts] = Screen('Flip', wh, next_ts);
            next_ts = next_ts + ts_i;
    end
end