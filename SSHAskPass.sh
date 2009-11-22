#!/bin/bash
/usr/bin/osascript <<EOT
tell application "System Events"
	activate
	set prompt to "Please enter your CVS password:"
	set dialogResult to display dialog prompt ¬
		buttons {"OK"} default button ¬
		"OK" default answer "" with icon 1 with hidden answer
	copy text returned of dialogResult to stdout
end tell
EOT
