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

    let motionMgr = CMMotionManager()
    let motionUpdateInterval: NSTimeInterval = 0.01

    // Low-pass filters used if we only have accelerometer data rather than gyroscope
    var smoothGravityX = LowPassFilterSignal(value: 0, filterFactor: 0.85)
    var smoothGravityY = LowPassFilterSignal(value: 0, filterFactor: 0.85)


    // MARK: View lifecycle

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        startMotionUpdates()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        stopMotionUpdates()
    }


    // MARK: Rotation handling

    func onMotionUpdateGravityX(gravityX: Double, gravityY: Double) {

        var rotation = atan2(gravityX, gravityY)

        switch UIDevice.currentDevice().orientation {
        case .Portrait:           rotation -= M_PI
        case .PortraitUpsideDown: break
        case .LandscapeLeft:      rotation += M_PI_2
        case .LandscapeRight:     rotation -= M_PI_2
        default:                  break
        }

        testImage.transform = CGAffineTransformMakeRotation(CGFloat(rotation))
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
