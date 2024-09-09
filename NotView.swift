import Foundation
import UIKit
import CoreBluetooth
struct Intruder: Identifiable, Equatable {
    var id = UUID()
    var name: String
    var rssi: Double
    var timestamp: Date
}

struct PeripheralData: Identifiable {
    let id = UUID()
    let name: String
    var distance: Double
    var identifier: UUID
}

extension NotView {
    func getPeripheral(with identifier: UUID) -> CBPeripheral? {
        return nodos.keys.first(where: { $0.identifier == identifier })
    }
}

class NotView: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, ObservableObject, CBPeripheralManagerDelegate {
    
    private var centralManager: CBCentralManager!
    private var peripheralManager: CBPeripheralManager!
   
    @Published var isScanning = false
    @Published var nodos: [CBPeripheral: Double] = [:]
    @Published var distance: Double?
    @Published var conectado = false
    @Published var pariado = false
    @Published var connectedPeripheral: CBPeripheral?
    @Published var discoveredServices: [CBService] = []
    @Published var discoveredCharacteristics: [CBCharacteristic] = []
    private var characteristic: CBMutableCharacteristic?
    private let serviceUUID = CBUUID(string: "1234")
    private let characteristicUUID = CBUUID(string: "5678")
    var connectedCentrals: [CBCentral] = []
    @Published var showAlert: Bool = false
    var alertMessage: String = ""
    @Published var intruders: [Intruder] = []
    var authCharacteristic: CBMutableCharacteristic!
    @Published var connectingDeviceName: String?
    @Published var enteredPin: String?
    @Published var isShowingPinView: Bool = false
    @Published  var showIntruderList = false
    @Published var authorizedDevices: [Intruder] = []
    var uuidToAuthorize: UUID?
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    func verifyPin(_ pin: String) {
            if pin == "1234" { // Comparar con el PIN recibido o esperado
                self.alertMessage = "PIN Correcto: \(pin)"
                isShowingPinView = false
            
                if let uuid = uuidToAuthorize, let index = intruders.firstIndex(where: { $0.id == uuid }) {
                    let authorizedIntruder = intruders.remove(at: index)
                    authorizedDevices.append(authorizedIntruder)
                            }
               
                            
              
            } else {
                self.alertMessage = " Pin inCorrecto: \(pin)"
            }
            self.showAlert = true
        }
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            let service = CBMutableService(type: serviceUUID, primary: true)
            characteristic = CBMutableCharacteristic(
                type: characteristicUUID,
                properties: [.read, .write, .notify],
                value: nil,
                permissions: [.readable, .writeable]
            )
            service.characteristics = [characteristic!]
            peripheralManager.add(service)
            print("Peripheral Manager está encendido.")
        } else {
            print("Bluetooth no está disponible.")
        }
    }
  
    func startAdvertising(withName name: String) {
        let authCharacteristic = CBMutableCharacteristic(
            type: characteristicUUID, // Usando characteristicUUID
            properties: [.write],
            value: nil,
            permissions: [.writeable]
        )
        
        let authService = CBMutableService(type: serviceUUID, primary: true) // Usando serviceUUID
        authService.characteristics = [authCharacteristic]
        
        peripheralManager.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [authService.uuid]
        ])
        
        print("Publicidad iniciada con el nombre: \(name)")
    }

   
       
       func updateAdvertisingName(to newName: String) {
           peripheralManager?.stopAdvertising()
           startAdvertising(withName: newName)
       }
   
    func disconnect() {
        if let connectedPeripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(connectedPeripheral)
            
            print("Disconnecting from peripheral...")
        }
        connectedPeripheral = nil
        conectado = false
      
    }
    
    func connect(to peripheral: CBPeripheral) {
        centralManager.connect(peripheral, options: nil)
        connectedPeripheral = peripheral
        print("Conectando al periférico: \(peripheral.name ?? "Desconocido")")
      
    }
    
    func startScanning() {
        if !isScanning && centralManager.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            isScanning = true
            print("Empezando a escanear")
        }
    }

    func stopScanning() {
        if isScanning {
            centralManager.stopScan()
            isScanning = false
            print("Deteniendo el escaneo")
        }
    }
    func sendConnectNotification(to peripheral: CBPeripheral) {
        let peripheralName = peripheral.name ?? "Dispositivo Desconocido"
        let alertMessage = "¡Alerta! El dispositivo \(peripheralName) se ha conectado."
        
        DispatchQueue.main.async {
            self.alertMessage = alertMessage
            self.showAlert = true
        }
    }
 
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
          
        } else {
            print("Bluetooth no está disponible.")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if let txPowerLevel = advertisementData[CBAdvertisementDataTxPowerLevelKey] as? NSNumber {
           
                }
        if let advertisedName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
          //  print("Peripheral descubierto con nombre personalizado: \(advertisedName)")
        } else {
           // print("Peripheral descubierto con nombre de hardware: \(peripheral.name ?? "Desconocido")")
        }

        peripheral.delegate = self
        if peripheral.name != "" {
            connectedPeripheral = peripheral
            let distance = calculateDistance(rssi: RSSI.doubleValue)
            nodos[peripheral] = distance
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Conectado al periférico: \(peripheral.name ?? "Desconocido")")
        connectedPeripheral = peripheral
        peripheral.delegate = self
        peripheral.discoverServices([])
        conectado = true

      

     
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error al actualizar el valor para la característica: \(error.localizedDescription)")
            return
        }
        
        if let value = characteristic.value, let alertMessage = String(data: value, encoding: .utf8) {
            self.alertMessage = alertMessage
                    showAlert = true
            print("Mensaje recibido: \(alertMessage)")
           
        }
    }
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Error al conectar con el periférico: \(peripheral.name ?? "Desconocido")")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Desconectado del periférico: \(peripheral.name ?? "Desconocido")")
        connectedPeripheral = nil
        conectado = false
       
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error al descubrir servicios: \(error.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else { return }
        
        for service in services {
            if !discoveredServices.contains(where: { $0.uuid == service.uuid }) {
                print("Servicio descubierto: \(service.uuid)")
                discoveredServices.append(service)
                                peripheral.discoverCharacteristics(nil, for: service)
            } else {
                
                print("Servicio ya descubierto: \(service.uuid)")
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error al descubrir características: \(error.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
          
          
            if characteristic.uuid == characteristicUUID {
                        peripheral.setNotifyValue(true, for: characteristic)
                        print("Suscrito a notificaciones de la característica: \(characteristic.uuid)")
                    }
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        
        let centralName = central.identifier.uuidString
        if shouldAllowConnection(for: central) {
            let newIntruder = Intruder(name: centralName, rssi: 0, timestamp: Date())
            let serviceUUID = characteristic.service?.uuid.uuidString ?? "UUID desconocido"
              DispatchQueue.main.async {
                  self.intruders.append(newIntruder)
                  self.alertMessage = "¡Alerta \(UIDevice.current.name)! Un dispositivo desconocido se ha conectado: \(newIntruder.name)  intentó suscribirse al servicio \(serviceUUID)."
                  self.showAlert = true
              }
            
            
        } else {
            let newIntruder = Intruder(name: centralName, rssi: 0, timestamp: Date()) // RSSI es 0 porque no tenemos esa información aquí
            intruders.append(newIntruder)
            alertMessage = "¡Alerta \(UIDevice.current.name)! Anuncio detenido debido a un dispositivo no autorizado: UUID \(centralName)  intentó suscribirse al servicio \(serviceUUID)."
                 
          showAlert = false //  el alert de al principio de pinview
            
        }
       
    }
  

    func shouldAllowConnection(for central: CBCentral) -> Bool {
        // Lógica para determinar si el dispositivo debe permitirse o no
        // Por ejemplo, podrías usar una lista blanca o negra de UUIDs
        let allowedUUIDs: Set<String> = ["UUID-permitido", "UUID-NOpermitido"]
        return allowedUUIDs.contains(central.identifier.uuidString)
    }
    func disconnectUnauthorizedDevice(for central: CBCentral) {
        // Simula una desconexión forzando el cese de la comunicación
        peripheralManager.stopAdvertising()  // Deja de anunciar
        // Aquí podrías eliminar suscripciones o dejar de enviar actualizaciones
    }
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("Central unsubscribed from characteristic: \(central.identifier.uuidString)")
        if let index = connectedCentrals.firstIndex(where: { $0.identifier == central.identifier }) {
           
            connectedCentrals.remove(at: index)
        }
        if connectedCentrals.isEmpty {
                   
           
            // Notify the central about the disconnection
                }
    }
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            // Verificar si la solicitud es para la característica de autenticación
            if let authCharacteristic = authCharacteristic, request.characteristic.uuid == authCharacteristic.uuid {
                if let value = request.value, let receivedPIN = String(data: value, encoding: .utf8) {
                                   // Puedes almacenar el PIN recibido para compararlo más tarde
                                   self.enteredPin = receivedPIN
                                   DispatchQueue.main.async {
                                       self.alertMessage = "PIN recibido: \(receivedPIN)"
                                       self.showAlert = false
                                   }
                               } else {
                        print("PIN incorrecto, dispositivo no autorizado")
                        // Responder al dispositivo que la escritura no está permitida
                        peripheralManager.respond(to: request, withResult: .writeNotPermitted)
                    }
                }
            }
        }
    

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        print("Received read request for characteristic: \(request.characteristic.uuid.uuidString)")
        if let characteristic = characteristic, request.characteristic.uuid == characteristic.uuid {
            if let value = characteristic.value,let receivedPIN = String(data: value, encoding: .utf8) {
                request.value = value
                peripheralManager.respond(to: request, withResult: .success)
                DispatchQueue.main.async {
                    self.alertMessage = "Dispositivo autorizado con PIN: \(receivedPIN)"
                    self.showAlert = true}
            } else {
                print("PIN incorrecto, dispositivo no autorizado")
                                   peripheralManager.respond(to: request, withResult: .writeNotPermitted)
                // Mostrar alerta de PIN incorrecto
                                    DispatchQueue.main.async {
                                        self.alertMessage = "PIN incorrecto: "
                                        self.showAlert = false
                                    }
            }
        } else {
            peripheralManager.respond(to: request, withResult: .attributeNotFound)
        }
    }
    
    func calculateDistance(rssi: Double) -> Double {
        let txPower: Double = -59 // Valor de referencia, típicamente -59 dBm a 1 metro
        
        if rssi == 0 {
            return -1.0 // No se puede determinar la distancia
        }
        
        let ratio = rssi / txPower
        if ratio < 1.0 {
            return pow(ratio, 10) // Cercano al transmisor
        } else {
            return (0.89976) * pow(ratio, 7.7095) + 0.111 // Más lejos del transmisor
        }
    }
    
    func DatosdeUsuarios(for id: Int) -> String {
        switch id {
        case 1:
            return "Hola"
        case 2:
            return "Te Ayudo?"
        default:
            return "Buscando"
        }
    }
}
