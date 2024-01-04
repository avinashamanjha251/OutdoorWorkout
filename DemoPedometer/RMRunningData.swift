//
//  RMRunningData.swift
//  DemoPedometer
//
//  Created by Avinash Aman on 04/01/24.
//

import RealmSwift

typealias VoidCompletionHandler = (() -> Void)


class RMRunningData: Object {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var steps: String = ""
    @Persisted var distance: Double = 0.0
    @Persisted var pace: String = ""
    @Persisted var created: Double = 0.0
}

class RMMotionData: Object {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var xUserAcceleration: Double = 0.0
    @Persisted var yUserAcceleration: Double = 0.0
    @Persisted var zUserAcceleration: Double = 0.0
    @Persisted var xGravity: Double = 0.0
    @Persisted var yGravity: Double = 0.0
    @Persisted var zGravity: Double = 0.0
    @Persisted var created: Double = 0.0
}

class RMStateData: Object {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var unknown: Bool = false
    @Persisted var stationary: Bool = false
    @Persisted var walking: Bool = false
    @Persisted var running: Bool = false
    @Persisted var automotive: Bool = false
    @Persisted var cycling: Bool = false
    @Persisted var created: Double = 0.0
    
    var stringValue: String {
        if unknown {
            return "Unknown"
        } else if stationary {
            return "Stationary"
        } else if walking {
            return "Walking"
        } else if running {
            return "Running"
        } else if automotive {
            return "Automotive"
        } else if cycling {
            return "Cycling"
        } else {
            return "Unknown"
        }
    }
}


struct RMObserver {
    static var pedometerObserver: NotificationToken?
    static var motionobserver: NotificationToken?
    static var stateObserver: NotificationToken?
}

class RMRunningViewModel {
    
}

extension RMRunningViewModel {
    static var pedometerObserver: NotificationToken? {
        set {
            RMObserver.pedometerObserver = newValue
        }
        get {
            return RMObserver.pedometerObserver
        }
    }
    
    static func storeActivityList(list: List<RMRunningData>,
                                  completion: VoidCompletionHandler?) {
        do {
            let realm = try Realm()
            try realm.write {
                realm.add(list,
                          update: .all)
            }
            let observer = realm.objects(RMRunningData.self)
            pedometerObserver = observer.observe { changes in
                self.removeObserverForPedometer()
                completion?()
            }
        } catch {
            print(error)
        }
    }
    
    private static func removeObserverForPedometer() {
        pedometerObserver?.invalidate()
        pedometerObserver = nil
    }
}

extension RMRunningViewModel {
    static var motionObserver: NotificationToken? {
        set {
            RMObserver.motionobserver = newValue
        }
        get {
            return RMObserver.motionobserver
        }
    }
    
    static func storeMotionList(list: List<RMMotionData>,
                                completion: VoidCompletionHandler?) {
        do {
            let realm = try Realm()
            try realm.write {
                realm.add(list,
                          update: .all)
            }
            let observer = realm.objects(RMMotionData.self)
            motionObserver = observer.observe { changes in
                self.removeObserverForMotion()
                completion?()
            }
        } catch {
            print(error)
        }
    }
    
    private static func removeObserverForMotion() {
        motionObserver?.invalidate()
        motionObserver = nil
    }
}


extension RMRunningViewModel {
    static var stateObserver: NotificationToken? {
        set {
            RMObserver.stateObserver = newValue
        }
        get {
            return RMObserver.stateObserver
        }
    }
    
    static func storeStateList(list: List<RMStateData>,
                                completion: VoidCompletionHandler?) {
        do {
            let realm = try Realm()
            try realm.write {
                realm.add(list,
                          update: .all)
            }
            let observer = realm.objects(RMStateData.self)
            motionObserver = observer.observe { changes in
                self.removeObserverForState()
                completion?()
            }
        } catch {
            print(error)
        }
    }
    
    private static func removeObserverForState() {
        motionObserver?.invalidate()
        motionObserver = nil
    }
}

extension RMRunningViewModel {
    static func fetchAllPedometerRecord() -> Results<RMRunningData>? {
        do {
            let realm = try Realm()
            let elementList = realm.objects(RMRunningData.self)
            let historyList = elementList.sorted(byKeyPath: "created",
                                                 ascending: true)
            return historyList
        } catch {
            print(error)
            return nil
        }
    }
    
    static func fetchAllMotionRecord() -> Results<RMMotionData>? {
        do {
            let realm = try Realm()
            let elementList = realm.objects(RMMotionData.self)
            let historyList = elementList.sorted(byKeyPath: "created",
                                                 ascending: true)
            return historyList
        } catch {
            print(error)
            return nil
        }
    }
    
    static func fetchAllStateRecord() -> Results<RMStateData>? {
        do {
            let realm = try Realm()
            let elementList = realm.objects(RMStateData.self)
            let historyList = elementList.sorted(byKeyPath: "created",
                                                 ascending: true)
            return historyList
        } catch {
            print(error)
            return nil
        }
    }
}
