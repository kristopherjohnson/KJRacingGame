//
//  ViewController.swift
//  KJRacingGame
//
//  Created by Kristopher Johnson on 7/26/15.
//  Copyright © 2015 Kristopher Johnson. All rights reserved.
//

import UIKit
import CoreMotion


struct LowPassFilterSignal {
    var value: Double
    let filterFactor: Double

    mutating func update(newValue: Double) {
        value = filterFactor * value + (1.0 - filterFactor) * newValue
    }
}


class ViewController: UIViewController {

    @IBOutlet weak var testImage: UIImageView!

    var displayLink: CADisplayLink!

    var rotationAngle: Double = 0.0

    let motionMgr = CMMotionManager()
    let motionUpdateInterval: NSTimeInterval = 0.01

    // Low-pass filters used if we only have accelerometer data rather than gyroscope
    var smoothGravityX = LowPassFilterSignal(value: 0, filterFactor: 0.85)
    var smoothGravityY = LowPassFilterSignal(value: 0, filterFactor: 0.85)


    // MARK: View lifecycle

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        startMotionUpdates()
        startScreenUpdates()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        stopMotionUpdates()
        stopScreenUpdates()
    }


    // MARK: Screen updates

    func onScreenUpdate(displayLink: CADisplayLink) {
        testImage.transform = CGAffineTransformMakeRotation(CGFloat(rotationAngle))
    }

    func startScreenUpdates() {
        displayLink = CADisplayLink(target: self, selector: "onScreenUpdate:")
        displayLink.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
    }

    func stopScreenUpdates() {
        displayLink.invalidate()
    }

    // MARK: Rotation handling

    func onMotionUpdateGravityX(gravityX: Double, gravityY: Double) {

        var rot = atan2(gravityX, gravityY)

        switch UIDevice.currentDevice().orientation {
        case .Portrait:           rot -= M_PI
        case .PortraitUpsideDown: break
        case .LandscapeLeft:      rot += M_PI_2
        case .LandscapeRight:     rot -= M_PI_2
        default:                  break
        }

        rotationAngle = rot
    }

    func startMotionUpdates() {
        if motionMgr.deviceMotionAvailable {
            motionMgr.deviceMotionUpdateInterval = motionUpdateInterval
            motionMgr.startDeviceMotionUpdatesToQueue(NSOperationQueue.mainQueue()) { [weak self] (data: CMDeviceMotion?, error: NSError?) -> Void in
                guard let data = data else { return }
                guard let vc = self else { return }
                vc.onMotionUpdateGravityX(data.gravity.x, gravityY: data.gravity.y)
            }
        }
        else if motionMgr.accelerometerAvailable {
            motionMgr.accelerometerUpdateInterval = motionUpdateInterval
            motionMgr.startAccelerometerUpdatesToQueue(NSOperationQueue.mainQueue()) { [weak self] (data: CMAccelerometerData?, error: NSError?) in
                guard let data = data else { return }
                guard let vc = self else { return }

                // Accelerometer data is jittery, so use low-pass filter to smooth it
                vc.smoothGravityX.update(data.acceleration.x)
                vc.smoothGravityY.update(data.acceleration.y)

                vc.onMotionUpdateGravityX(vc.smoothGravityX.value, gravityY: vc.smoothGravityY.value)
            }
        }
        else {
            NSLog("!!! device motion updates not available !!!")
        }
    }

    func stopMotionUpdates() {
        if motionMgr.deviceMotionAvailable {
            motionMgr.stopDeviceMotionUpdates()
        }
        else if motionMgr.accelerometerAvailable {
            motionMgr.stopAccelerometerUpdates()
        }
    }
}
