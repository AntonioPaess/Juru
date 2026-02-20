//
//  AppConfig.swift
//  Juru
//
//  Centralized configuration for layout, timing, and gesture thresholds.
//  All magic numbers should be defined here for maintainability.
//

import SwiftUI

/// Centralized configuration constants for the Juru app.
/// Organized by category for easy maintenance and adjustment.
enum AppConfig {

    // MARK: - Gesture Timing

    /// Time constants for gesture recognition and interaction feedback.
    enum Timing {
        /// Duration to hold pucker for selection action (seconds)
        static let selectHoldDuration: Double = 1.2

        /// Duration to hold pucker for undo/back action (seconds)
        static let backHoldDuration: Double = 2.0

        /// Interval for TimelineView ticks (50ms = 20Hz, matches ARKit)
        static let tickInterval: TimeInterval = 0.05

        /// Interval for face tracking verification checks
        static let faceCheckInterval: TimeInterval = 0.2

        /// Time without face anchor before showing "not detected" overlay
        static let faceDetectionTimeout: TimeInterval = 0.5

        /// Calibration countdown start value
        static let calibrationCountdown: Double = 3.9

        /// Demo animation cycle duration in calibration
        static let demoCycleDuration: Double = 2.5

        /// Success feedback animation duration
        static let successFeedbackDuration: Double = 1.2

        /// Delay before enabling user turn after demo
        static let demoToUserTurnDelay: Double = 3.0

        // Tutorial timing constants moved to AppConfig.Tutorial
    }

    // MARK: - Gesture Thresholds

    /// Threshold values for gesture detection sensitivity.
    enum Thresholds {
        /// Default eyebrow raise threshold (0.0 - 1.0)
        static let browDefault: Double = 0.3

        /// Default mouth pucker threshold (0.0 - 1.0)
        static let puckerDefault: Double = 0.5

        /// Trigger factor multiplied with calibrated threshold
        static let triggerFactor: Double = 0.6

        /// Minimum valid calibration value
        static let minCalibrationValue: Double = 0.1

        /// Hysteresis factor for pucker release detection
        static let puckerHysteresis: Double = 0.1

        /// Throttle interval for gesture state updates
        static let throttleInterval: Double = 0.05
    }

    // MARK: - Layout Scales

    /// Scale factors for different device sizes and orientations.
    enum Scale {
        /// Scale for iPad in landscape orientation
        static let iPadLandscape: CGFloat = 1.2

        /// Scale for iPad in portrait orientation
        static let iPadPortrait: CGFloat = 1.3

        /// Scale for iPhone (base scale)
        static let iPhone: CGFloat = 1.0

        /// Scale for OnBoarding on iPad landscape
        static let onboardingIPadLandscape: CGFloat = 1.1

        /// Scale for OnBoarding on iPad portrait
        static let onboardingIPadPortrait: CGFloat = 1.2

        /// Scale multiplier for avatar in landscape layout
        static let avatarLandscapeMultiplier: CGFloat = 1.1

        /// Scale for feedback center on iPad
        static let feedbackCenterIPad: CGFloat = 1.3

        /// Returns appropriate scale for device and orientation
        static func forDevice(isPad: Bool, isLandscape: Bool) -> CGFloat {
            guard isPad else { return iPhone }
            return isLandscape ? iPadLandscape : iPadPortrait
        }

        /// Returns appropriate scale for onboarding
        static func forOnboarding(isPad: Bool, isLandscape: Bool) -> CGFloat {
            guard isPad else { return iPhone }
            return isLandscape ? onboardingIPadLandscape : onboardingIPadPortrait
        }
    }

    // MARK: - Layout Dimensions

    /// Fixed dimensions and proportions for UI elements.
    enum Layout {
        /// Content width proportion for landscape left panel
        static let landscapeLeftPanelWidth: CGFloat = 0.4

        /// Content width proportion for onboarding left panel
        static let onboardingLeftPanelWidth: CGFloat = 0.45

        /// Content width proportion for onboarding right panel
        static let onboardingRightPanelWidth: CGFloat = 0.55

        /// Portrait content height proportion
        static let portraitContentHeight: CGFloat = 0.45

        /// Max height for typing display card on iPad
        static let typingCardMaxHeightIPad: CGFloat = 240

        /// Max height for typing display card on iPhone
        static let typingCardMaxHeightIPhone: CGFloat = 180

        /// Action card height
        static let actionCardHeight: CGFloat = 200

        /// Progress ring size
        static let progressRingSize: CGFloat = 160

        /// Avatar size in calibration
        static let calibrationAvatarSize: CGFloat = 260

        /// Avatar size in feedback center
        static let feedbackCenterAvatarSize: CGFloat = 100

        /// Avatar container size in feedback center
        static let feedbackCenterContainerSize: CGFloat = 120

        /// Intensity gauge height
        static let intensityGaugeHeight: CGFloat = 60

        /// Header bottom padding
        static let headerBottomPadding: CGFloat = 10

        /// Arrow indicator bottom padding in tutorial
        static let arrowIndicatorBottomPadding: CGFloat = 4

        /// Active color blur circle size in feedback center
        static let activeColorBlurSize: CGFloat = 140

        /// Avatar container shadow radius
        static let avatarContainerShadowRadius: CGFloat = 15

        /// Avatar container shadow Y offset
        static let avatarContainerShadowY: CGFloat = 8

        /// Speaking pulse animation delay multiplier
        static let speakingPulseDelayStep: Double = 0.4
    }

    // MARK: - Padding Values

    /// Standard padding values used throughout the app.
    enum Padding {
        /// Extra small padding (8pt)
        static let xs: CGFloat = 8

        /// Small padding (12pt)
        static let sm: CGFloat = 12

        /// Medium padding (16pt)
        static let md: CGFloat = 16

        /// Large padding (20pt)
        static let lg: CGFloat = 20

        /// Extra large padding (24pt)
        static let xl: CGFloat = 24

        /// 2x Extra large padding (30pt)
        static let xxl: CGFloat = 30

        /// 3x Extra large padding (40pt)
        static let xxxl: CGFloat = 40

        /// Huge padding (50pt)
        static let huge: CGFloat = 50

        /// Side margin for landscape panels
        static let landscapeSideMargin: CGFloat = 60

        /// Horizontal padding for iPad content
        static let horizontalIPad: CGFloat = 80

        /// Horizontal padding for iPhone content
        static let horizontalIPhone: CGFloat = 24

        /// Horizontal padding for tutorial on iPad
        static let tutorialHorizontalIPad: CGFloat = 100

        /// Bottom padding for tutorial card on iPhone
        static let tutorialCardBottomIPhone: CGFloat = 130

        /// Returns appropriate horizontal padding for device
        static func horizontal(isPad: Bool) -> CGFloat {
            isPad ? horizontalIPad : horizontalIPhone
        }

        /// Returns appropriate tutorial horizontal padding
        static func tutorialHorizontal(isPad: Bool) -> CGFloat {
            isPad ? tutorialHorizontalIPad : horizontalIPhone
        }
    }

    // MARK: - Corner Radius

    /// Standard corner radius values for UI elements.
    enum CornerRadius {
        /// Small radius for buttons and chips
        static let sm: CGFloat = 16

        /// Medium radius for cards
        static let md: CGFloat = 24

        /// Large radius for main containers
        static let lg: CGFloat = 28

        /// Extra large radius for display cards
        static let xl: CGFloat = 32
    }

    // MARK: - Animation

    /// Animation duration and configuration values.
    enum Animation {
        /// Standard spring response time
        static let springResponse: Double = 0.4

        /// Standard spring damping fraction
        static let springDamping: Double = 0.7

        /// Quick animation duration
        static let quick: Double = 0.1

        /// Standard animation duration
        static let standard: Double = 0.3

        /// Slow animation duration
        static let slow: Double = 0.5

        /// Speaking pulse animation duration
        static let speakingPulse: Double = 1.5
    }

    // MARK: - Calibration

    /// Configuration specific to the calibration flow.
    enum Calibration {
        /// Number of samples to collect for neutral baseline
        static let neutralSampleCount: Int = 20

        /// Progress ring stroke width
        static let progressRingStrokeWidth: CGFloat = 12

        /// Progress ring track opacity
        static let progressRingTrackOpacity: Double = 0.1

        /// Avatar size inside progress ring
        static let avatarSize: CGFloat = 240

        /// Progress ring total size (avatar + ring padding)
        static let ringSize: CGFloat = 280

        /// Checkmark icon size on success
        static let successIconSize: CGFloat = 80

        /// Countdown font size
        static let countdownFontSize: CGFloat = 72

        /// Status pill icon size
        static let statusIconSize: CGFloat = 20

        /// Status pill font size
        static let statusFontSize: CGFloat = 15
    }

    // MARK: - Onboarding

    /// Configuration specific to the onboarding flow.
    enum Onboarding {
        /// Auto-advance timer duration per page (seconds)
        static let autoAdvanceDuration: Double = 15.0

        /// Segmented progress bar height
        static let progressBarHeight: CGFloat = 3.0

        /// Apple-style button corner radius
        static let buttonCornerRadius: CGFloat = 14.0

        /// Button height
        static let buttonHeight: CGFloat = 50.0

        /// Maximum button width
        static let maxButtonWidth: CGFloat = 360.0

        /// Maximum text content width
        static let maxContentWidth: CGFloat = 500.0

        /// Title font size
        static let titleFontSize: CGFloat = 34.0

        /// Subtitle font size
        static let subtitleFontSize: CGFloat = 17.0

        /// Countdown badge size
        static let countdownBadgeSize: CGFloat = 32.0
    }

    // MARK: - Tutorial

    /// Configuration specific to the tutorial flow.
    enum Tutorial {
        /// Duration of "Show" demo phases before auto-advancing to "Do" (seconds)
        static let showDemoDuration: Double = 5.0

        /// Standard intro phase auto-advance delay (seconds)
        static let introDelay: Double = 3.0

        /// Extended intro delay for complex instructions (seconds)
        static let extendedDelay: Double = 4.0

        /// Quick transition delay after typing/selection completion (seconds)
        static let quickDelay: Double = 0.5

        /// Delay after speaking action before advancing (seconds)
        static let speakingDelay: Double = 2.0

        /// Delay before tutorial completion callback (seconds)
        static let completionDelay: Double = 4.0

        /// Success feedback flash duration (seconds)
        static let successFeedback: Double = 0.6

        /// Instruction card maximum width
        static let cardMaxWidth: CGFloat = 520.0

        /// Instruction card corner radius
        static let cardCornerRadius: CGFloat = 20.0

        /// Title font size (matching Apple-like pattern)
        static let titleFontSize: CGFloat = 28.0

        /// Subtitle font size
        static let subtitleFontSize: CGFloat = 17.0

        /// Demo scene height inside instruction card
        static let demoHeight: CGFloat = 200.0

        /// Demo scene scale factor
        static let demoScale: CGFloat = 0.85

        /// Cheat sheet bottom padding
        static let cheatSheetBottomPadding: CGFloat = 16.0

        /// Focus highlight pulse animation duration
        static let focusPulseDuration: Double = 1.2

        /// Arrow indicator bounce offset
        static let arrowBounceOffset: CGFloat = 6.0

        /// Action pill shadow radius
        static let actionPillShadowRadius: CGFloat = 5.0

        /// Action pill shadow Y offset
        static let actionPillShadowY: CGFloat = 2.0

        /// iPad instruction card column width (leading side)
        static let iPadCardColumnWidth: CGFloat = 380.0
    }

    // MARK: - Progress Ring (MainTypingView)

    /// Configuration for the pucker progress ring in MainTypingView.
    enum ProgressRing {
        /// Stroke width for the ring
        static let strokeWidth: CGFloat = 8

        /// Icon badge size inside ring
        static let iconBadgeSize: CGFloat = 40

        /// Icon font size inside badge
        static let iconFontSize: CGFloat = 20

        /// Icon badge offset from center (negative Y = upward)
        static let iconOffsetY: CGFloat = -90
    }
}
