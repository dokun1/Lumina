# Contributing to Lumina

First off - thank you!!!

## The goal

Lumina is designed to be simple. Using Lumina at it's most basic should always try to consist of writing three lines of code to create the camera, assign a delegate, and presenting it.

Since Xcode can now stub out the delegate methods for you, Lumina should make the developer feel as though getting a camera up and running was quick.

## Branching

If you would like to fork Lumina, feel free to do so. If you would like to contribute to Lumina, please clone the repository, make a branch, and submit a PR from that branch. This is to allow CI to do its job properly with access to [Danger Systems](https://danger.systems).

## Pull Requests

Please submit any feature requests or bug fixes as a pull request.

Please make sure that all pull requests have the following:

- a descriptive title
- a meaningful body of text to explain what the PR does
- if it fixes a pre-existing issue, include the issue number in the body of text

Pushing directly to master is disallowed.

## Running locally

To run Lumina locally, please follow these steps:

- Clone the repository
- Open `Lumina.xcworkspace`
- Select the `Lumina` framework scheme, and build for an iOS device
- Find the built product in the Products folder in the `Lumina` framework project file, and show it in the Finder
- Drag that framework to the `Frameworks` folder in the `LuminaSample` project file
- Open the project file settings for `LuminaSample`, and add the framework to the `Embedded Binaries` dialog

If any of these steps are confusing, please watch [this](https://www.lynda.com/Swift-tutorials/Using-exercise-files/636120/680702-4.html) video for an example of how to do this with an identical framework I created in a course I taught on [lynda.com](https://www.lynda.com/Swift-tutorials/Welcome/636120/680700-4.html).

**Thanks for contributing! :100:**
