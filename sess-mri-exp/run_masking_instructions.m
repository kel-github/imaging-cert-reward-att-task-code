function [] = run_masking_instructions(wh, gabor_rect, white, grey, glb_alph, task)    

    Screen('TextStyle', wh, 1);
    Screen('TextSize', wh, 30); 

    instructions = ...
        sprintf(['Welcome back! :) Remember, tt is very important that you\n' ... 
                 'keep your eyes fixed on the cross in the middle\n' ...
                 'of the screen at all times.\n\n'...
                 'Press a key to continue.']);
    DrawFormattedText(wh, instructions, 'Center', 'Center', white, 115);
    Screen('Flip', wh);
 
    start_ts = KbWait;
    WaitSecs(0.5);
    
    instructions = ...
        sprintf(['Press %s for clockwise and %s for counterclockwise.\n'...
                 'Press any key to start\n'], ...
                KbName(task.responses(1)), KbName(task.responses(2)));
    DrawFormattedText(wh, instructions, 'Center', 'Center', white, 115);
    Screen('Flip', wh);

    WaitSecs(0.5);
    start_ts = KbWait;
end