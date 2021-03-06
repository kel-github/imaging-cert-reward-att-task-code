function [] = run_newbie_instructions(wh, gabor_id, gabor_rect, white, grey, task)    

    Screen('TextStyle', wh, 1);
    Screen('TextSize', wh, 30); 
    instructions = ...
        sprintf(['During each trial of this task, you will see two\n'...
                 'gratings presented, one each on the left and right\n'...
                 'on the screen.\n\n'...
                 'Press a key now to see an example.\n']);
    DrawFormattedText(wh, instructions, 'Center', 'Center', white, 115);
    Screen('Flip', wh);
    start_ts = KbWait;
    WaitSecs(0.5);
    draw_targets(wh, gabor_id, gabor_rect, 1, 45, 0, 1.0);
    Screen('Flip', wh);
    start_ts = KbWait;
    WaitSecs(0.5);
    instructions = ...
        sprintf(['The goal is to identify which direction the target\n'...
                 'grating has been rotated. The target is the grating\n'...
                 'that is not vertical or horizontal.\n\n'...
                 'Press a key now to see a clockwise example.\n']);
    DrawFormattedText(wh, instructions, 'Center', 'Center', white, 115);
    Screen('Flip', wh);
    start_ts = KbWait;
    WaitSecs(0.5);
    instructions = ...
        sprintf(['Here the target on the right is rotated clockwise.\n']);
    DrawFormattedText(wh, instructions, 'Center', 'Center', white, 115);
    draw_targets(wh, gabor_id, gabor_rect, 2, -45, 1, 1.0);
    draw_placeholders(wh, 2, white);
    Screen('Flip', wh);
    start_ts = KbWait;
    WaitSecs(0.5);
    instructions = ...
        sprintf(['The target presentation will be very brief \n' ...
        'It is very important that you keep your eyes fixed\n'...
        'on the cross in the middle of the screen at all\n'...
        'times.\n\n'...
        'Press a key to continue.']);
    DrawFormattedText(wh, instructions, 'Center', 'Center', white, 115);
    Screen('Flip', wh);
    start_ts = KbWait;
    WaitSecs(0.5);
    instructions = ...
        sprintf(['Press %s for clockwise and %s for counterclockwise.\n'...
                 'Be as accurate and as efficient as you can.\n' ...
                 'Press any key to have a go\n'], ...
                 KbName(task.responses(1)), KbName(task.responses(2)));
             
     DrawFormattedText(wh, instructions, 'Center', 'Center', white, 115);
     Screen('Flip', wh);
     start_ts = KbWait;
     WaitSecs(0.5);
end