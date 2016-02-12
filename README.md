# PeekView
When implementing peek, pop and preview actions with 3D Touch, you may want to support such features for users accessing your app from older devices that don't provide 3D Touch capibility. PeekView hence can be used as an alternative in such case.

![Preview](https://github.com/itsmeichigo/PeekView/blob/master/peekview.gif)
![Screenshot](https://github.com/itsmeichigo/PeekView/blob/master/screenshot.png)

(Please ignore the low resolution of the GIF. Try the demo for actual experience.)

## Note

Things that need approving
- Content view panned: Smoother animation
- Action style: Selected functionality
- More customizable UI if needed (requests are welcome)
- Bug fixes if any

## Requirements

[PeekView](#) supports devices without 3D touch capibility running iOS 8 and later.

## Getting Started

#### Install using Cocoapods

Just add the following line in to your pod file:
  
	pod 'PeekView'

#### Manual Install

Drag and drop folder named `Source` in your project and you're done.

### Usage

- Add `UILongPressGestureRecognizer` to the view you want to peek (i.e table view cell, image, hypertext, etc.)
- Create a `UIViewController` instance as the content of your peek view; then set your desire frame for the content view. It's recommended to leave a 15px padding for both left and right margin of your content view.
- If you want to include preview actions, prepare an array containing title of the buttons and its preview style. Don't forget to prepare completion handlers for when each button is tapped.

Sample snippet:

```Swift
  PeekView.viewForController(
  parentViewController: self, 
  contentViewController: controller, 
  expectedContentViewFrame: frame, 
  fromGesture: gestureRecognizer, 
  shouldHideStatusBar: true, 
  withOptions: ["Option 1": .Destructive, "Option 2": .Default, "Option 3": .Selected], 
  completionHandler: { optionIndex in
                    switch optionIndex {
                    case 0:
                        print("Option 1 selected")
                    case 1:
                        print("Option 2 selected")
                    case 2:
                        print("Option 3 selected")
                    default:
                        break
                    }
                })
```

Be sure to check out the demo code for better understanding of the usage.

### ARC

PeekView uses ARC. If you are using PeekView in a non-arc project, you
will need to set a `-fobjc-arc` compiler flag on every PeekView source files. To set a
compiler flag in Xcode, go to your active target and select the "Build Phases" tab. Then select
PeekView source files, press Enter, insert -fobjc-arc and then "Done" to enable ARC
for PeekView.

## Contributing

Contributions for bug fixing or improvements are welcome. Feel free to submit a pull request.

## Licence

PeekView is available under the MIT license. See the LICENSE file for more info.
