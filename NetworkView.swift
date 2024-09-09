import SwiftUI
import CoreBluetooth
struct CustomAlertView: View {
    @Binding var isPresented: Bool
    var message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
            
            VStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.white)
                
                Text("Alerta de Conexión")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                Text(message)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button("OK") {
                    isPresented = false
                }
                .padding()
                .background(Color.white)
                .foregroundColor(.blue)
                .cornerRadius(10)
            }
            .padding()
            .background(Color.blue)
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding(30)
        }
    }
}

struct Point: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGPoint
    var name: String
    var rssi: Double
    var identifier: UUID
    var state: Bool
}
struct DeviceDetailView: View {
    var point: Point
    
    @EnvironmentObject var mc:  NotView
    var body: some View {
        ScrollView{
            VStack {
                
            
                HStack {
                    
                    Button(action: {
                        if let peripheral = mc.getPeripheral(with: point.identifier) {
                            mc.connect(to: peripheral)
                            print("Conectando a \(point.name)")
                        } else {
                            print("Periférico no encontrado")
                        }
                        
                        
                    }) {
                        Text("Conectar")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    Button(action: {
                        mc.disconnect()
                        
                        print("Botón 2 presionado")
                    }) {
                        Text("Desconectar")
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
                if mc.conectado{
                    Text("Detalles")
                        .font(.title)
                    let symbol = mc.conectado ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
                    let color = mc.conectado ? Color(UIColor.systemGreen) : Color(UIColor.systemRed)
                    
                    Image(systemName: symbol)
                        .foregroundColor(color)
                        .imageScale(.large)
                    Text("Estado: \(mc.conectado  ? "Connectado" : "Desconnectado")")
                    Text("Pariado: \(mc.pariado  ? "SI" : "No")")
                    Text("UUID: \(point.identifier)")
                    Text("Name: \(point.name)")
                    Text("Distancia Aproximada: \(point.rssi) metros")
                    Text("point id \(point.id)")
                 
                                   Section(header: Text("Servicios")) {
                                       ForEach(mc.discoveredServices, id: \.uuid) { service in
                                               
                                           Text("Servicio: \(service.uuid)")
                                          
                                       }.background(Color.clear)
                                   }.background(Color.clear)
                       
                                   Section(header: Text("Características")) {
                                       ForEach(mc.discoveredCharacteristics, id: \.uuid) { characteristic in
                                           Text("Característica: \(characteristic.uuid)")
                                               .padding(2)
                                       }.background(Color.clear)
                                           .foregroundColor(Color.white)
                                   } .background(Color.clear)
                                  
                                        
                }else{
                    Text("Detalles")
                        .font(.title)
                    let symbol = mc.conectado ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
                    let color = mc.conectado ? Color(UIColor.systemGreen) : Color(UIColor.systemRed)
                    
                    Image(systemName: symbol)
                        .foregroundColor(color)
                        .imageScale(.large)
                    Text("Estado: \(mc.conectado  ? "Connectado" : "Desconnectado")")
                    
                }
                
                
                
            } }
        
        .padding()
    }
       
}

struct NetworkView: View {
    @StateObject var mc = NotView()
    @State var Btscan :Bool = false
    @State private var points: [Point] = []
    @State private var deviceIdentifiers: [UUID] = []
    @State private var showUnnamedDevices: Bool = false
    @State private var totalDevices: Int = 0
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showCustomAlert = false
    @State private var distanceThreshold: Double = 0.0
    @State var showsheet = false
    var pointCount : Int = 0
    let pointSize: CGFloat = 8.0
    let lineDistance: CGFloat = 109
   
    let screenSize = UIScreen.main.bounds.size
    
    var body: some View {
        
        
        
        
        GeometryReader { geometry in
            
            if points.count < 1{
          
                Text(" \(points.count) Nodo").foregroundColor(.white)
                    .font(.system(size: 20))
                    .position(CGPoint(x: 200, y: 400))
                
            }
            else{
                ForEach(points) { point in
                    HStack{
                        Text("Total Devices : \(totalDevices)")
                        
                            .position(CGPoint(x: 200, y: 200))
                    }
                    
                }
                .sheet(isPresented: $showsheet, content: {
                    NavigationView {  // Envolver la hoja en un NavigationView
                        ZStack {
                            List {
                                ForEach(points) { point in
                                    if point.name != "Unknown" {
                                        
                                        NavigationLink(destination: DeviceDetailView(point: point)) {
                                        
                                            if point.rssi < 10 {
                                                Text("\(point.name != "Unknown" ? point.name : point.name) : \(point.rssi) metros")
                                                   
                                                    .padding()
                                                    .foregroundColor(Color.green)
                                            }else{ Text("\(point.name != "Unknown" ? point.name : point.name) : \(point.rssi) metros")
                                                
                                                    .padding()
                                                    .foregroundColor(Color.white)}
                                            
                                           
                                            
                                        }
                                    }else if point.name == "Unknown"  && showUnnamedDevices {
                                        NavigationLink(destination: DeviceDetailView(point: point)) {
                                            if point.rssi < 10 {Text("\(point.name != "Unknown" ? point.name : point.identifier .uuidString) : \(point.rssi) metros")
                                                .foregroundColor(Color.green)}else{Text("\(point.name != "Unknown" ? point.name : point.identifier .uuidString) : \(point.rssi) metros")
                                                    .foregroundColor(Color.gray)}
                                            
                                            
                                            
                                        }
                                    }
                                    
                                    
                                }.border(.clear)
                                
                                
                            }
                        }
                        .presentationDetents(mc.isScanning ? [.fraction(0.3)] : [.fraction(1.0)])
                    }
                })
            }
            
            Canvas { context, size in
                for point in points {
                    
                    
                    if !showUnnamedDevices && point.name == "Unknown" {
                        
                        continue
                    }
                    let circleColor: Color = point.name == "Unknown" ? .purple : .blue
                    context.fill(
                        Circle()
                            .path(in: CGRect(x: point.position.x, y: point.position.y, width: 9, height: 9)),
                        with: .color(circleColor)
                    )
                    if point.rssi < 3 && distanceThreshold >= 90{
                        
                        let textPosition = CGPoint(x: point.position.x + pointSize + 5, y: point.position.y)
                        context.draw(
                            
                            Text("\(point.name)")
                                .foregroundColor(.green)
                                .font(.system(size: 25)),
                            at: textPosition
                        )
                        
                    }else if point.rssi < 23 && distanceThreshold >= 60{
                        //  if point.name != "Unknown" {
                        let textPosition = CGPoint(x: point.position.x + pointSize + 5, y: point.position.y)
                        context.draw(
                            Text("\(point.name)")
                                .foregroundColor(.yellow)
                                .font(.system(size: 14)),
                            at: textPosition
                        )
                        
                        
                    }else {
                        let textPosition = CGPoint(x: point.position.x + pointSize + 5, y: point.position.y)
                        context.draw(
                            Text("\(point.name)")
                                .foregroundColor(.white)
                                .font(.system(size: 12)),
                            at: textPosition
                        )
                        
                    }
                    
                    
                    // Dibujar líneas entre puntos cercanos
                    for otherPoint in points {
                        if distance(point.position, otherPoint.position) < lineDistance {
                            
                            
                            
                            
                            
                            var path = Path()
                            path.move(to: point.position)
                            path.addLine(to: otherPoint.position)
                            context.stroke(path, with: .color(.blue), lineWidth: 1.0)
                            
                        }
                    }
                }
            }
            .onAppear {
                initializePoints(size: geometry.size)
                startAnimation()
                mc.startAdvertising(withName: "Light")
            }
            .onDisappear{
                mc.stopScanning()
            }
           

            Toggle("Unknown", isOn: $showUnnamedDevices)
                .padding()
                .foregroundColor(.red)
                .font(.title)
                .position(CGPoint(x: 200, y: 760))
            Toggle(Btscan ? "encendido" : "apagado",systemImage:Btscan ? "dot.radiowaves.right" : "antenna.radiowaves.left.and.right.slash",isOn: $Btscan ).toggleStyle(.button)
                .font(.system(size: 25))
                .position(CGPoint(x: 200, y: 700))
            Text("acercarse")
                .font(.title)
                .position(CGPoint(x: 200, y: 740))
            if Btscan{
                Slider(value: $distanceThreshold, in: 0...100, step: 16)
                {
                } .position(CGPoint(x: 200, y: 800))
                
            }
           
            
            Toggle(showsheet ? "" : "",systemImage:showsheet ? "pencil.and.list.clipboard" : "list.bullet.rectangle.portrait",isOn: $showsheet ).toggleStyle(.button)
                .font(.system(size: 45))
            
                .position(CGPoint(x: 335, y: 700))
            
            if Btscan{
                let _: () = mc.startScanning()
            }else{
                let _: () = mc.stopScanning()
            }
        } 
        .overlay(
            Group {
                if showCustomAlert {
                    CustomAlertView(isPresented: $showCustomAlert, message: mc.alertMessage)
                }
            }
        )
        .onChange(of: mc.showAlert) { newValue in
            showCustomAlert = newValue
            
        }
        
        .environmentObject(mc)
        .onReceive(mc.$nodos) { devices in
            for (peripheral, rssi) in devices where !deviceIdentifiers.contains(peripheral.identifier) {
                addPoint(for: peripheral, rssi: rssi, in: screenSize)
                deviceIdentifiers.append(peripheral.identifier)
                let namedDevices = devices.filter { $0.key.name != nil && !$0.key.name!.isEmpty }
                let unnamedDevices = devices.filter { $0.key.name == nil || $0.key.name!.isEmpty }
                totalDevices = showUnnamedDevices ? unnamedDevices.count : namedDevices.count
                
            }
        } .onChange(of: showUnnamedDevices) {
            
            // Recalcular el total de dispositivos con nombres
            let namedDevices = mc.nodos.filter { $0.key.name != nil && !$0.key.name!.isEmpty }
            totalDevices = showUnnamedDevices ? mc.nodos.count  :namedDevices.count
        }
        
        .background(Color.black)
        .edgesIgnoringSafeArea(.all)
         }
    
    
    
  
 
    func addPoint(for device: CBPeripheral,rssi: Double,in size: CGSize) {
           let newPoint = Point(
               position: CGPoint(
                   x: CGFloat.random(in: 0..<size.width),
                   y: CGFloat.random(in: 0..<size.height)
               ),
               velocity: CGPoint(
                   x: CGFloat.random(in: -1.0...1.0),
                   y: CGFloat.random(in: -1.0...1.0)
               ), name: device.name ?? "Unknown",rssi: rssi,identifier: device.identifier,state: false
           )
           points.append(newPoint)
       }
    // Inicializar los puntos al inicio
    func initializePoints(size: CGSize) {
        points = (0..<pointCount).map { _ in
            Point(
                position: CGPoint(
                    x: CGFloat.random(in: 0..<size.width),
                    y: CGFloat.random(in: 0..<size.height)
                ),
                velocity: CGPoint(
                    x: CGFloat.random(in: -1.0...1.0),
                    y: CGFloat.random(in: -1.0...1.0)
                ), name: "Unknown",rssi: 0,identifier: UUID(), state: false
            )
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

    
    // Mover los puntos y actualizar la vista continuamente
    func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            movePoints()
        }
    }

    func movePoints() {
        for i in 0..<points.count {
            var point = points[i]
            point.position.x += point.velocity.x
            point.position.y += point.velocity.y
            
            // Rebotar en los bordes
            if point.position.x < 0 || point.position.x > screenSize.width {
                point.velocity.x *= -1
            }
            if point.position.y < 0 || point.position.y > screenSize.height {
                point.velocity.y *= -1
            }
            
            points[i] = point
        }
    }

    func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        return sqrt(pow(b.x - a.x, 2) + pow(b.y - a.y, 2))
    }
    
}




#Preview {
    NetworkView()
}
