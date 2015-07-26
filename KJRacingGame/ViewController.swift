//
//  ViewController.swift
//  KJRacingGame
//
//  Created by Kristopher Johnson on 7/26/15.
//  Copyright © 2015 Kristopher Johnson. All rights reserved.
//

import UIKit
import CoreMotion

class ViewController: UIViewController {

    @IBOutlet weak var testImage: UIImageView!

    let motionManager = CMMotionManager()
    let motionUpdateInterval: NSTimeInterval = 0.01


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
        if motionManager.deviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = motionUpdateInterval
            motionManager.startDeviceMotionUpdatesToQueue(NSOperationQueue.mainQueue()) { [weak self] (data: CMDeviceMotion?, error: NSError?) -> Void in
                guard let data = data else { return }
                guard let vc = self else { return }
                vc.onMotionUpdateGravityX(data.gravity.x, gravityY: data.gravity.y)
            }
        }
        else if motionManager.accelerometerAvailable {
            motionManager.accelerometerUpdateInterval = motionUpdateInterval
            motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.mainQueue()) { [weak self] (data: CMAccelerometerData?, error: NSError?) in
                guard let data = data else { return }
                guard let vc = self else { return }
                vc.onMotionUpdateGravityX(data.acceleration.x, gravityY: data.acceleration.y)

                // TODO: accelerometer data is jittery.  Need to smooth it.
            }
        }
        else {
            NSLog("!!! device motion updates not available !!!")
        }
    }

    func stopMotionUpdates() {
        if motionManager.deviceMotionAvailable {
            motionManager.stopDeviceMotionUpdates()
        }
        else if motionManager.accelerometerAvailable {
            motionManager.stopAccelerometerUpdates()
        }
    }
}
