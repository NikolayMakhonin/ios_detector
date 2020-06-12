//
//  ViewController.swift
//  App
//
//  Created by NikolayMakhonin on 2020/06/12
//

class Device {
    var peripheral: CBPeripheral!
    var rssi: NSNumber!
    var updateTime: TimeInterval!
}

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBPeripheralDelegate, CBCentralManagerDelegate {

    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral!
    // Characteristics
    private var countChar: CBCharacteristic?
    private var devices: [UUID: Device] = [:]
    
    // @IBOutlet weak var TextViewESP32: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // If we're powered on, start scanning
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central state update")
        if central.state != .poweredOn {
            print("Central is not powered on")
        } else {
            print("Central scanning for ...");
            central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
    }
    
    // Handles the result of the scan
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {

        print("\(RSSI) | \(peripheral.name ?? "\(peripheral.identifier)")")
        
        var device = devices[peripheral.identifier]
        if (device == nil) {
            device = Device()
            devices[peripheral.identifier] = device
        }
        
        device!.peripheral = peripheral
        device!.rssi = RSSI
        device!.updateTime = NSDate().timeIntervalSince1970
        
        var devicesArray = Array(devices.values)
        devicesArray.sort(by: {
            if ($0.updateTime > 10) {
                if ($1.updateTime > 10) {
                    return $0.updateTime < $1.updateTime
                }
                return true
            }
            if ($1.updateTime > 10) {
                return false
            }
            return Double(truncating: $0.rssi) > Double(truncating: $1.rssi)
        })
        
        var devicesStr = devicesArray
            .map({ "\($0.rssi ?? 0) | \($0.peripheral.name ?? "\($0.peripheral.identifier)")"})
            .joined(separator: "\n")
        
        // peripherals[peripheral.identifier] = peripheral
        // peripheral.readRSSI()
        
        // We've found it so stop scan
        // self.centralManager.stopScan()

        // Copy the peripheral instance
        // self.peripheral = peripheral
        // peripheral.delegate = self
        // central.stopScan()
        // central..scanForPeripherals(withServices: nil, options: nil)

    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        print("\(RSSI) \(peripheral.name ?? "\(peripheral.identifier)")")
    }
    
    func _peripheralDidUpdateRSSI(_ peripheral: CBPeripheral, error: Error?) {
        // print("\(peripheral.rssi) \(peripheral.name ?? "\(peripheral.identifier)")")
    }

    // The handler if we do connect succesfully
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("centralManager2 \(peripheral)")
        // if peripheral == self.peripheral {
        //    print("Connected to your Count Board")
        // }
    }

    // Handles discovery event
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("peripheral")
        if let services = peripheral.services {
            for service in services {
                print("service in for : " + String(describing: service))
            }
        }
    }
    
    // Handling discovery of characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("peripheral2")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        print("peripheral3")
        print("didWriteValue for characteristic")
        if let error = error {
            print("didWriteValueFailed… error: \(error)")
            return
        }
    }
        
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("peripheral4")
        print("didupdatevalue for characteristic")
        if let error = error {
            print("didupdatevalueFailed… error: \(error)")
            return
        }

        print("characteristic uuid: \(characteristic.uuid), value: \(String(describing: characteristic.value))")
        
    }
}
