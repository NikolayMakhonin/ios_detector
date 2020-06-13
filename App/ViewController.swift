//
//  ViewController.swift
//  App
//
//  Created by NikolayMakhonin on 2020/06/12
//

class Device {
    var peripheral: CBPeripheral!
    var rssi: NSNumber!
    var updateDate: NSDate!
}

import UIKit
import CoreBluetooth
import AVFoundation
// import NetworkExtension
import ExternalAccessory

class ViewController: UIViewController, CBPeripheralDelegate, CBCentralManagerDelegate, EAWiFiUnconfiguredAccessoryBrowserDelegate {

    private var centralManager: CBCentralManager!
    private var devices: [UUID: Device] = [:]
    private var lastScannedDate: NSDate = NSDate()
    private var count0: Int = 0
    private var count1: Int = 0
    private var count2: Int = 0
    @IBOutlet weak var labelState: UILabel!
    @IBOutlet weak var labelCount0: UILabel!
    @IBOutlet weak var labelCount1: UILabel!
    @IBOutlet weak var labelCount2: UILabel!
    private var externalAccessoryBrowser: EAWiFiUnconfiguredAccessoryBrowser!
    // private var accessoryBrowser = HMAccessoryBrowser()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: updateState)
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        // NEHotspotConfigurationManager.shared.getConfiguredSSIDs()
        
        // let interfaces = NEHotspotHelper.supportedNetworkInterfaces()
        // print("--- \(interfaces)")
        
        // accessoryBrowser.delegate = self
        // accessoryBrowser.startSearchingForNewAccessories()

        // externalAccessoryBrowser = EAWiFiUnconfiguredAccessoryBrowser(delegate: self, queue: nil)
        // externalAccessoryBrowser.startSearchingForUnconfiguredAccessories(matching: nil)
    }
       
    func updateState(timer: Timer) {
        var devicesArray = Array(devices.values)
        devicesArray.sort(by: {
            if (-$0.updateDate.timeIntervalSinceNow > 10) {
                if (-$1.updateDate.timeIntervalSinceNow > 10) {
                    return -$0.updateDate.timeIntervalSinceNow < -$1.updateDate.timeIntervalSinceNow
                }
                return false
            }
            if (-$1.updateDate.timeIntervalSinceNow > 10) {
                return true
            }
            return Double(truncating: $0.rssi) > Double(truncating: $1.rssi)
        })
        
        let devicesStr = devicesArray
            .prefix(50)
            .filter({ -$0.updateDate.timeIntervalSinceNow < 60 * 60 })
            .map({ "\($0.rssi ?? 0) | \(Int(-$0.updateDate.timeIntervalSinceNow)) | \($0.peripheral.name ?? "\($0.peripheral.identifier)")"})
            .joined(separator: "\n")
        
        labelState.text = "power\(centralManager.state == .poweredOn ? "On" : "Off") \(centralManager.isScanning ? "scanning" : "") \(devicesArray.count)\n\(devicesStr)"
        
        let _count0 = devicesArray.filter({ -$0.updateDate.timeIntervalSinceNow <= 10 }).count
        let _count1 = devicesArray.filter({ -$0.updateDate.timeIntervalSinceNow <= 60 * 3 }).count
        let _count2 = devicesArray.filter({ -$0.updateDate.timeIntervalSinceNow <= 60 * 30 }).count
        
        labelCount0.text = "\(_count0)"
        labelCount1.text = "\(_count1)"
        labelCount2.text = "\(_count2)"

        if (count1 < 3 && _count1 > count1) {
            // UINotificationFeedbackGenerator().notificationOccurred(.warning)
            // UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            print("vibrate")
        }

        // print("refresh: \(devicesArray.count)")
        
        count0 = _count0
        count1 = _count1
        count2 = _count2
     
        if (centralManager.state == .poweredOn
            && (!centralManager.isScanning || -lastScannedDate.timeIntervalSinceNow > 10)) {
            lastScannedDate = NSDate()
            // centralManager.stopScan()
            centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
    }
    
    // MARK: bluetooth
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central state update")
        if central.state != .poweredOn {
            print("Central is not powered on")
        } else {
            print("Central scanning for ...");
            // centralManager.stopScan()
            central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {

        // print("\(RSSI) | \(peripheral.name ?? "\(peripheral.identifier)")")
        
        var device = devices[peripheral.identifier]
        if (device == nil) {
            device = Device()
            devices[peripheral.identifier] = device
        }
        
        device!.peripheral = peripheral
        device!.rssi = RSSI
        device!.updateDate = NSDate()
        
        lastScannedDate = NSDate()
    }
    
    // MARK: wi-fi
        
    func accessoryBrowser(_ browser: EAWiFiUnconfiguredAccessoryBrowser, didUpdate state: EAWiFiUnconfiguredAccessoryBrowserState) {
        print("wi-fi 1 \(state == .searching ? "wifi searching" : "other")")
        print("\(browser.unconfiguredAccessories.count)")
    }
    
    func accessoryBrowser(_ browser: EAWiFiUnconfiguredAccessoryBrowser, didFindUnconfiguredAccessories accessories: Set<EAWiFiUnconfiguredAccessory>) {
        print("wi-fi 2")
    }
    
    func accessoryBrowser(_ browser: EAWiFiUnconfiguredAccessoryBrowser, didRemoveUnconfiguredAccessories accessories: Set<EAWiFiUnconfiguredAccessory>) {
        print("wi-fi 3")
    }
    
    func accessoryBrowser(_ browser: EAWiFiUnconfiguredAccessoryBrowser, didFinishConfiguringAccessory accessory: EAWiFiUnconfiguredAccessory, with status: EAWiFiUnconfiguredAccessoryConfigurationStatus) {
        print("wi-fi 4")
    }
}
