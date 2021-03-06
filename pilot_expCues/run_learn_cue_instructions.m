function [] = run_learn_cue_instructions(wh, white) 

    Screen('TextStyle', wh, 1);
    Screen('TextSize', wh, 30); 
    instructions = ...
        sprintf(['From now, before the target appears you will \n' ...
                 'see an arrow in the centre of the screen\n\n'...
                 'The arrow will point to the left, to the right,\n', ...
                 'or will be bidirectional.\n\n' ...
                 'The arrows provide probabilistic information\n'...
                 'about where your target could be.\n\n'...
                 'Although it wont be completely 100 %% correct, it will\n'...
                 'be a good clue\n\n'...
                 'Good luck!']);
    DrawFormattedText(wh, instructions, 'Center', 'Center', white, 115);
    Screen('Flip', wh);
    start_ts = KbWait;

    WaitSecs(0.5);
end