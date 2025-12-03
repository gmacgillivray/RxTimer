#!/bin/bash

# Generate audio files for WorkoutTimer app

echo "🎵 Generating audio files for WorkoutTimer..."

# 1. Create silence.m4a (1 second of silence for background audio)
echo "Creating silence.m4a..."
ffmpeg -f lavfi -i anullsrc=r=44100:cl=mono -t 1 -c:a aac -b:a 64k silence.m4a -y 2>/dev/null || {
    # Fallback: use sox or afconvert
    say -o silence.aiff "" 2>/dev/null
    afconvert -f m4af -d aac silence.aiff silence.m4a 2>/dev/null
    rm -f silence.aiff
}

# 2. Create start.caf (workout start sound)
echo "Creating start.caf..."
say -v Samantha -o start_temp.aiff "Start" 2>/dev/null
afconvert -f caff -d LEI16 start_temp.aiff start.caf 2>/dev/null
rm -f start_temp.aiff

# 3. Create tick.caf (interval tick sound)
echo "Creating tick.caf..."
say -v Samantha -o tick_temp.aiff "Tick" 2>/dev/null
afconvert -f caff -d LEI16 tick_temp.aiff tick.caf 2>/dev/null
rm -f tick_temp.aiff

# 4. Create warn.caf (warning sound)
echo "Creating warn.caf..."
say -v Samantha -o warn_temp.aiff "Warning" 2>/dev/null
afconvert -f caff -d LEI16 warn_temp.aiff warn.caf 2>/dev/null
rm -f warn_temp.aiff

# 5. Create beep_1hz.caf (countdown beep)
echo "Creating beep_1hz.caf..."
say -v Samantha -o beep_temp.aiff "Beep" 2>/dev/null
afconvert -f caff -d LEI16 beep_temp.aiff beep_1hz.caf 2>/dev/null
rm -f beep_temp.aiff

# 6. Create end.caf (workout complete sound)
echo "Creating end.caf..."
say -v Samantha -o end_temp.aiff "Complete" 2>/dev/null
afconvert -f caff -d LEI16 end_temp.aiff end.caf 2>/dev/null
rm -f end_temp.aiff

# 7. Create countdown voice files (three, two, one, go)
echo "Creating countdown audio files..."
say -v Samantha -r 160 -o three_temp.aiff "Three" 2>/dev/null
afconvert -f caff -d LEI16 three_temp.aiff three.caf 2>/dev/null
rm -f three_temp.aiff

say -v Samantha -r 160 -o two_temp.aiff "Two" 2>/dev/null
afconvert -f caff -d LEI16 two_temp.aiff two.caf 2>/dev/null
rm -f two_temp.aiff

say -v Samantha -r 160 -o one_temp.aiff "One" 2>/dev/null
afconvert -f caff -d LEI16 one_temp.aiff one.caf 2>/dev/null
rm -f one_temp.aiff

say -v Samantha -r 160 -o go_temp.aiff "Go" 2>/dev/null
afconvert -f caff -d LEI16 go_temp.aiff go.caf 2>/dev/null
rm -f go_temp.aiff

echo "✅ Audio files generated!"
ls -lh *.{caf,m4a} 2>/dev/null
