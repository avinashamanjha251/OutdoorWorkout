//
//  ViewController.swift
//  DemoPedometer
//
//  Created by Avinash Aman on 04/01/24.
//

import UIKit
import CoreMotion
import RealmSwift

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segment: UISegmentedControl!
    let pedometer = CMPedometer()
    let activityManager = CMMotionActivityManager()
    let motionManager = CMMotionManager()

    var dataList: List<RMRunningData> = List<RMRunningData>()
    var motionDataList: List<RMMotionData> = List<RMMotionData>()
    var stateDataList: List<RMStateData> = List<RMStateData>()

    var pedometerResultList: Results<RMRunningData>?
    var motionResultList: Results<RMMotionData>?
    var stateResultList: Results<RMStateData>?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // Check if step counting is available on this device
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        pedometerResultList = RMRunningViewModel.fetchAllPedometerRecord()
        motionResultList = RMRunningViewModel.fetchAllMotionRecord()
        stateResultList = RMRunningViewModel.fetchAllStateRecord()
        startPedoMeter()
        if CMPedometer.isStepCountingAvailable() &&  CMPedometer.isPaceAvailable() {
            startPedometerUpdates()
        } else {
            print("Step counting is not available on this device.")
        }
        reloadtTable()
    }
    
    func startPedoMeter() {
        activityManager.startActivityUpdates(to: OperationQueue.main) { (activity: CMMotionActivity?) in
            guard let activity = activity else { return }
            let model = RMStateData()
            model.created = Date().toMillis()
            model.unknown = activity.unknown
            model.stationary = activity.stationary
            model.walking = activity.walking
            model.running = activity.running
            model.automotive = activity.automotive
            model.cycling = activity.cycling
            self.stateDataList.append(model)
            if activity.stationary {
                print("Stationary")
            } else if activity.walking {
                print("Walking")
            } else if activity.running {
                print("Running")
            } else if activity.automotive {
                print("Automotive")
            }
        }
        
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 4.5
            motionManager.startDeviceMotionUpdates(to: OperationQueue.main) { (data, error) in
                let model: RMMotionData = RMMotionData()
                model.created = Date().toMillis()
                if let acceleration = data?.userAcceleration {
                    model.xUserAcceleration = acceleration.x
                    model.yUserAcceleration = acceleration.y
                    model.zUserAcceleration = acceleration.z
                }
                if let gravity = data?.gravity {
                    model.xGravity = gravity.x
                    model.yGravity = gravity.y
                    model.zGravity = gravity.z
                }
                self.motionDataList.append(model)
            }
            DispatchQueue.delay(5) {
                self.storeMotionData()
            }
        }
    }
    
    func paceInSecondsPerMeterToSpeedInKmph(paceSecondsPerMeter: Double) -> Double {
        // Convert pace to speed (inverse of pace) and multiply by 3.6
        return 1.0 / paceSecondsPerMeter * 3.6
    }
    
    func startPedometerUpdates() {
        pedometer.startUpdates(from: Date()) { data, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            } else if let data = data {
                DispatchQueue.mainQueueAsync {
                    // Update UI with real-time data
                    print("Number of steps: \(data.numberOfSteps.stringValue)")
                    print("Distance: \(data.distance?.doubleValue ?? 0) meters")
                    print("Pace: \(String(describing: data.currentPace)) seconds per meter")
                    // Add more properties as needed
                    let model = RMRunningData()
                    model.steps = data.numberOfSteps.stringValue
                    model.distance = data.distance?.doubleValue ?? 0
                    let paceInSecondsPerMeter = data.currentPace?.doubleValue ?? 0
                    if paceInSecondsPerMeter == 0 {
                        model.pace = "Nil"
                    } else {
                        let speedInKmph = self.paceInSecondsPerMeterToSpeedInKmph(paceSecondsPerMeter: paceInSecondsPerMeter)
                        let str = String(format: "%.2f kmph", speedInKmph)
                        model.pace = str
                    }
                    model.created = Date().toMillis()
                    self.dataList.append(model)
                }
            }
        }
        DispatchQueue.delay(5) {
            self.storeData()
        }
    }
    
    func storeData() {
        RMRunningViewModel.storeActivityList(list: dataList) {
            self.reloadtTable()
            DispatchQueue.delay(5) {
                self.storeData()
            }
        }
    }
    
    func storeMotionData() {
        RMRunningViewModel.storeMotionList(list: motionDataList) {
            self.reloadtTable()
            DispatchQueue.delay(5) {
                self.storeMotionData()
            }
        }
        RMRunningViewModel.storeStateList(list: stateDataList) {
            self.reloadtTable()
        }
    }
    
    deinit {
        // Stop pedometer updates when the view controller is deallocated
        pedometer.stopUpdates()
    }
}

extension ViewController {
    
    @IBAction func segmentClicked(_ sender: UISegmentedControl) {
        reloadtTable()
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func reloadtTable() {
        DispatchQueue.mainQueueAsync { [weak self] in
            guard let self else { return }
            self.tableView.reloadData()
        }
    }
    // MARK: - Table View Data Source
    func tableView(_ tableView: UITableView, 
                   numberOfRowsInSection section: Int) -> Int {
        switch segment.selectedSegmentIndex {
            case 0:
                return pedometerResultList?.count ?? 0
            case 1:
                return motionResultList?.count ?? 0
            default:
                return stateResultList?.count ?? 0
        }
    }

    func tableView(_ tableView: UITableView, 
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.numberOfLines = 0
        switch segment.selectedSegmentIndex {
            case 0:
                if let data = pedometerResultList?[indexPath.row] {
                    // Example usage:
                    let doubleValue: Double = data.created // Replace with your specific Double value
                    let date = doubleToDate(timeInterval: doubleValue)

                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    let formattedDate = dateFormatter.string(from: date)
                    let distance = String(format: "%.2f mtr", data.distance)

                    let str = "Steps: \(data.steps)\n" + "Distance: \(distance)\n" + "Pace: \(data.pace) \n" + "Date: \(formattedDate)\n" + "------------------------------"
                    cell.textLabel?.text = str
                }
            case 1:
                if let data = motionResultList?[indexPath.row] {
                    let doubleValue: Double = data.created // Replace with your specific Double value
                    let date = doubleToDate(timeInterval: doubleValue)

                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    let formattedDate = dateFormatter.string(from: date)
//                    
//                    let gForcesX = convertAccelerationToGForces(acceleration: data.xUserAcceleration + data.xGravity)
//                    let gForcesY = convertAccelerationToGForces(acceleration: data.yUserAcceleration + data.yGravity)
//                    let gForcesZ = convertAccelerationToGForces(acceleration: data.zUserAcceleration + data.zGravity)
//              
                    let formattedAcceleration = self.formatUserAcceleration(data) + "\nDate: \(formattedDate)\n" + "------------------------------"
                    cell.textLabel?.text = formattedAcceleration
                }
            default:
                if let data = stateResultList?[indexPath.row] {
                    let doubleValue: Double = data.created // Replace with your specific Double value
                    let date = doubleToDate(timeInterval: doubleValue)

                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    let formattedDate = dateFormatter.string(from: date)
                    
                    cell.textLabel?.text = data.stringValue + "\nDate: \(formattedDate)\n" + "------------------------------"
                }
        }
        return cell
    }

    // MARK: - Table View Delegate
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        
    }
    
    func doubleToDate(timeInterval: Double) -> Date {
        return Date(timeIntervalSince1970: timeInterval/1000)
    }

    ///Acceleration is commonly measured in meters per second squared (m/s²). If you have an acceleration value and you want to convert it to a more readable format, you might consider expressing it in terms of gravitational acceleration or "g-forces" (where 1 g is approximately equal to 9.8 m/s², the acceleration due to gravity on Earth).
    func convertAccelerationToGForces(acceleration: Double) -> Double {
        let gravitationalAcceleration = 9.8
        let gForces = acceleration / gravitationalAcceleration
        return gForces
    }

    func formatUserAcceleration(_ acceleration: RMMotionData) -> String {
            return String(format: "X: %.2f m/s²,\nY: %.2f m/s²,\nZ: %.2f m/s²", acceleration.xUserAcceleration, acceleration.yUserAcceleration, acceleration.zUserAcceleration)
        }
}
