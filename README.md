#Xcode Source Editor Extension for VoiceCode

WORK IN PROGRESS

**how it works:**

- user says a command
- Xcode scope is active, so VoiceCode stashes the command
- VoiceCode presses a keystroke (control option v) that activates the Xcode plug-in
- Xcode queries the web socket to get the current command
- Xcode executes the command


keyboard shortcut: 

you need to assign a key binding (control option v) to trigger the extension from voice code. You can move the file

Default.idekeybindings

to

~/Library/Developer/Xcode/UserData