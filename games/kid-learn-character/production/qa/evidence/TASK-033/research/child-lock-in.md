# TASK-033 child lock-in research (Apple official sources, checked 2026-11-17)

Method note: developer.apple.com pages are JS-rendered; text was read from Apple's own DocC JSON
(https://developer.apple.com/tutorials/data/documentation/<path>.json), the same content as the doc pages.
Support-page text came through a summarising fetch; quotes there are as returned by the fetch and
should be re-eyeballed on the live page before being quoted in a shipped doc.

## 1. iPad Guided Access

URL: https://support.apple.com/en-us/111795 (Use Guided Access; page text fetched 2026-11-17)
(iPad User Guide copy: https://support.apple.com/guide/ipad/lock-ipad-to-one-app-with-guided-access-ipada16d1374/ipados - body not read, fetch truncated: not verified for that copy.)

Set up - verified (https://support.apple.com/en-us/111795):
1. Settings > Accessibility > Guided Access, turn it on.
2. Options there: Passcode Settings (set passcode; Face ID / Touch ID as another way to pause/end a session), Time Limits (sound + spoken remaining time), Accessibility Shortcut (show the shortcuts panel during a session), Display Auto-Lock.

Start - verified (same URL):
1. Open the app.
2. Triple-click the side button (iPhone) / top button (iPad).
3. If the Accessibility Shortcuts panel appears, tap Guided Access.
4. If previously configured for this app, the session starts at once with previous settings.
5. Circle parts of the screen to make them stop responding to touch.
6. Tap Session Settings (or Options) to change settings, then tap Start.
7. If no passcode was set during setup, you are prompted to set one.

What it restricts on iPad - verified (same URL):
- Buttons (top button, Home button, volume buttons listed separately): "Prevent use of this button, except to" pause the session.
- Volume Buttons: prevent use; iPadOS 26.1 or later also disables volume changes from Bluetooth headphone controls.
- Motion: limit how the device responds to motion.
- Keyboards: "Prevent the onscreen keyboard from appearing."
- Touch: "Ignore all screen touches"; plus circled areas of the screen disabled.
- Time Limit: after expiry a full-screen "Time Expired" message; triple-click and passcode to continue.

Hardware-keyboard shortcuts under Guided Access (Cmd+Tab, Cmd+H / Globe+H, Cmd+Space, Globe, Cmd+Q):
- not stated by Apple. The Guided Access page only mentions the ONSCREEN keyboard. A web search of support.apple.com found nothing on hardware-keyboard behaviour in Guided Access. Must be tested on a device (Apple Community thread https://discussions.apple.com/thread/255500413 asks about turning Guided Access on/off with a keyboard; unanswered; not official docs).

App-side API (all verified, DocC JSON under https://developer.apple.com/documentation/uikit/...):
- UIAccessibility.isGuidedAccessEnabled (iOS/iPadOS 6.0+, Mac Catalyst 13.1+, visionOS 1.0+): "A Boolean value that indicates whether the Guided Access setting is in an enabled state." https://developer.apple.com/documentation/uikit/uiaccessibility/isguidedaccessenabled
- UIAccessibility.guidedAccessStatusDidChangeNotification: "A notification that indicates when a Guided Access session starts or ends." No parameter; use default notification center; read isGuidedAccessEnabled afterwards. https://developer.apple.com/documentation/uikit/uiaccessibility/guidedaccessstatusdidchangenotification
- UIGuidedAccessRestrictionDelegate (iOS/iPadOS 7.0+): "A set of methods you use to add custom restrictions for the Guided Access feature". App returns string identifiers via guidedAccessRestrictionIdentifiers; default is allow; users deny via the Guided Access UI; app implements guidedAccessRestriction(withIdentifier:didChange:) and can poll guidedAccessRestrictionState(forIdentifier:). Apple's example: a photo app lets users disable deleting. https://developer.apple.com/documentation/uikit/uiguidedaccessrestrictiondelegate
- UIAccessibility.requestGuidedAccessSession(enabled:completionHandler:) (iOS/iPadOS 7.0+): "Transitions the app to or from Single App mode asynchronously." "Entering Single App mode is supported only for devices that are supervised using Mobile Device Management (MDM), and the app itself must be enabled for this mode by MDM. You must balance each call to enter Single App mode with a call to exit that mode." Completion handler gives Bool success. https://developer.apple.com/documentation/uikit/uiaccessibility/requestguidedaccesssession(enabled:completionhandler:)
- UIAccessibility.configureForGuidedAccess(features:enabled:completionHandler:) (iOS 12.2+): enable/disable accessibility features (per WWDC22: Zoom, VoiceOver, Invert Colors, AssistiveTouch, Grayscale) while in Guided Access. https://developer.apple.com/documentation/uikit/uiaccessibility/configureforguidedaccess(features:enabled:completionhandler:)
- Autonomous Single App Mode requirements, WWDC22 "Create accessible Single App Mode experiences" (https://developer.apple.com/videos/play/wwdc2022/10152/), verified quotes: "the device must be supervised, and the app that wants to use this API must be allow listed on the device's configuration profile, or the request to lock will fail because it's not privileged." and the app's bundle ID must be allowlisted "as an allowed application for Autonomous Single App Mode". Check state with isGuidedAccessEnabled; observe the notification. Consequence: a consumer parent's unsupervised iPad cannot use requestGuidedAccessSession; the parent-started Guided Access is the only consumer path.
- Related MDM docs (not read in full: not verified beyond titles): App Lock payload https://support.apple.com/guide/deployment/app-lock-payload-settings-dep80a981/web ; Automatic Assessment Configuration https://support.apple.com/en-us/101976 (search snippet only: needs Apple entitlement, no supervision; not verified).

What to do / avoid (WWDC22 10152, verified as the speaker's guidance, general not kid-specific): reduce dependence on timing/auto time-outs; be forgiving of errors; warn before irreversible actions; always confirm before payment; custom restrictions (UIGuidedAccessRestrictionDelegate) can lock risky in-app controls (Apple's example: an Account Settings button). Apple-doc-derived design implication (inference, not an Apple statement): put parent-only controls behind a Guided-Access custom restriction and/or a parent gate, and observe the status notification to adapt UI.
No Apple statement found on how an app should detect hardware keyboard shortcuts being blocked: not stated by Apple.

## 2. iPadOS: can an app block system shortcuts?

UIKeyCommand.wantsPriorityOverSystemBehavior - verified (https://developer.apple.com/documentation/uikit/uikeycommand/wantspriorityoversystembehavior), iOS/iPadOS 15.0+, Mac Catalyst 15.0+:
- Abstract: "A Boolean value that indicates whether the key command takes precedence over text input or focus movements."
- "In iOS 15 and later, the system delivers physical keyboard events to the text input or focus systems first. If those systems don't handle the keyboard input, the system delivers the events to your app's key commands. ... If the value of this property is true, the system reverses that order and delivers events to your key commands first and then to the text input and focus systems. The default value of this property is false."
- Pre-iOS 15 delivered to key commands first; apps linked against the iOS 14 SDK or earlier keep that.
- So it only reorders delivery between your app's key commands vs text-input/focus systems. Apple says nothing here about overriding system-level shortcuts (Cmd+Tab, Globe+H, Cmd+Space).
UIKeyCommand overview (https://developer.apple.com/documentation/uikit/uikeycommand), verified: "The system always has the first opportunity to handle key commands. Key commands that map to known system events (such as Cut, Copy, and Paste) are automatically routed to the appropriate responder methods."
Apple's shortcut list (https://support.apple.com/en-us/102393), verified: "Command-Tab: Switch to the next most recently used app among your open apps."; "Command-Space bar: Show or hide Spotlight."; "Globe-H: Go to the Home Screen."; Globe or Globe-E emoji; Globe-A Dock; Globe-C Control Center; Globe-M menu bar; Globe-N Lock Screen; Globe-F full screen. Cmd+H and Cmd+Q: not on that page (not verified for iPad).
Statement that Cmd+Tab / Cmd+H / Globe are reserved by the system and cannot be overridden by apps: not stated by Apple in sources found. Conclusion (inference): no documented app API blocks them; iPad lock-in must rely on Guided Access (parent) or MDM Single App Mode.

## 3. macOS NSApplication.PresentationOptions

URL: https://developer.apple.com/documentation/appkit/nsapplication/presentationoptions-swift.struct (macOS 10.6+). Abstract (verified): "Constants that control the presentation of the app, typically for fullscreen apps such as games or kiosks."

Options with Apple's descriptions (all verified at that URL; each has its own child page):
- autoHideDock: "The dock is normally hidden, but automatically appears when moused near."
- hideDock: "The dock is entirely hidden and disabled."
- autoHideMenuBar: "The menu bar is normally hidden, but automatically appears when moused near."
- hideMenuBar: "The menu bar is entirely hidden and disabled."
- disableAppleMenu: "All Apple Menu items are disabled."
- disableProcessSwitching: "The process switching user interface (Command + Tab to cycle through apps) is disabled."
- disableForceQuit: "The force quit panel (displayed by pressing Command + Option + Esc) is disabled"
- disableSessionTermination: "The panel that shows the Restart, Shut Down, and Log Out options that are displayed as a result of pushing the power key is disabled."
- disableHideApplication: "The app's "Hide" menu item is disabled."
- disableMenuBarTransparency: "The menu bar transparency appearance is disabled."
- fullScreen: "The app is in fullscreen mode."
- autoHideToolbar: "When in fullscreen mode the window toolbar is detached from window and hides and shows with autoHidden menuBar."
- disableCursorLocationAssistance: "The behavior that allows the user to shake the mouse to locate the cursor is disabled."
- NEW, macOS 27.0+: disableScreenCornerInteractions: "Disable screen corner interactions when the application is frontmost." Discussion: ".autoHideDock or .hideDock must also be set for this option to take effect." https://developer.apple.com/documentation/appkit/nsapplication/presentationoptions-swift.struct/disablescreencornerinteractions (hot corners; Apple does not say "hot corners" in the abstract - that reading is inference).

Combination rules, verbatim summary (verified, Overview of the struct page):
- autoHideDock and hideDock are mutually exclusive.
- autoHideMenuBar and hideMenuBar are mutually exclusive.
- hideMenuBar must be accompanied by hideDock.
- autoHideMenuBar must be accompanied by either hideDock or autoHideDock.
- Any of disableProcessSwitching, disableForceQuit, disableSessionTermination, disableMenuBarTransparency must be accompanied by either hideDock or autoHideDock.
- autoHideToolbar only when both fullScreen and autoHideMenuBar are also set.
- "When NSApplication receives a parameter value that does not conform to these requirements, it raises an invalidArgumentException."
Setter (verified, https://developer.apple.com/documentation/appkit/nsapplication/presentationoptions-swift.property): "The presentation options that should be in effect for the system when this app is active." "Trying to set the property to an invalid combination of option flags raises an invalidArgumentException exception." (NSInvalidArgumentException; Obj-C exception, not catchable by Swift do/catch: inference, validate flags before setting.)
Read-back: NSApplication.currentSystemPresentationOptions is KVO-observable (https://developer.apple.com/documentation/appkit/nsapplication/currentsystempresentationoptions); options take effect only while this app is active.

What disableProcessSwitching blocks: Apple's only statement is the Command+Tab process-switching UI. Whether Cmd+Opt+Esc (covered separately by disableForceQuit), Mission Control, Spotlight, Cmd+H, Cmd+Q are blocked: not stated by Apple for Mission Control / Spotlight / Cmd+Space / Cmd+H / Cmd+Q. Apple's NSApplication.terminate(_:) doc (https://developer.apple.com/documentation/appkit/nsapplication/terminate(_:)) says it is "typically invoked when the user chooses Quit"; nothing about presentation options blocking Cmd+Q (not stated; an app can instead cancel via applicationShouldTerminate, per the same page). disableHideApplication only disables the Hide menu item (Cmd+H is the menu item's shortcut: inference).
A developer-forum post (not official docs, https://developer.apple.com/forums/thread/111064 / 653093 as returned by search; not opened) reportedly annotates disableProcessSwitching as "Cmd+Tab UI is disabled. All Exposé functionality is also disabled." - treat as not verified (forum, unopened).
Apple statement of what cannot be blocked (e.g. power button hold, Touch ID/power long-press, Cmd+Ctrl+Q lock screen): not stated by Apple in these pages. disableSessionTermination covers only the power-key panel.
Carbon-era alias mentioned by Apple: SetSystemUIMode (referenced in currentSystemPresentationOptions page).

## 4. Sandboxed Mac App Store app and presentation options

Any official statement restricting NSApplication.presentationOptions under App Sandbox: not stated (no restriction found on the presentationOptions pages above; App Sandbox page https://developer.apple.com/documentation/security/app-sandbox not found to mention it). Search found only a forum report of a sandboxed kiosk losing key events with fullscreen+options (https://developer.apple.com/forums/thread/653093, unanswered, not opened: not verified). App Review treatment of disableProcessSwitching: not verified. Recommendation: test on a sandboxed, notarised build.
