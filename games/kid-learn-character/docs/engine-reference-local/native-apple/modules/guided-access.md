# Guided Access (iPad lock-in)

| Claim | Status |
|---|---|
| `UIAccessibility.isGuidedAccessEnabled` reports whether Guided Access is on | **SOURCED** — https://developer.apple.com/documentation/uikit/uiaccessibility/isguidedaccessenabled; **PROVEN (TASK-033)** to read `false` on the Simulator (not exercised) |
| `guidedAccessStatusDidChangeNotification` posts when a session starts or ends | **SOURCED** — https://developer.apple.com/documentation/uikit/uiaccessibility/guidedaccessstatusdidchangenotification |
| Single App mode by request needs an MDM-supervised device | **SOURCED** — https://developer.apple.com/documentation/uikit/uiaccessibility/requestguidedaccesssession(enabled:completionhandler:) |
| Whether hardware-keyboard shortcuts escape Guided Access | **NOT SOURCEABLE**: Apple does not say; device check in ADR-0008 |
