import SwiftUI
struct AuthorizedDevicesSheet: View {
    var authorizedDevices: [Intruder]
    
    @Environment(\.presentationMode) var presentationMode
    @State private var showAuthorizedDevicesSheet = false
    @State private var showCircle = false
    @State private var isLoading = false
    @State private var rssiUpdateTrigger = false
    @EnvironmentObject var mc: NotView
    @State private var selectedDeviceUUID: String = ""
    var body: some View {
        
        NavigationView {
            ZStack{
                ScrollView{
            let selectedDeviceUUID = mc.authorizedDevices[0].id.uuidString
                    Text(selectedDeviceUUID)
                        Spacer()
                        Button("Cerrar"){presentationMode.wrappedValue.dismiss() }
                            .padding()
                            .foregroundColor(Color.gray)
                                    .background(
                                        RoundedRectangle(cornerRadius: 25)
                                            .fill(Color.white)
                                            .shadow(color: .gray, radius: 2, x: 0, y: 2)
                                    )
                                    .buttonStyle(PlainButtonStyle())
                       }
                }}
          
                                            
                                           


                                      
        }
    }

struct AuthorizedDevicesView: View {
    @EnvironmentObject var mc: NotView
    @State private var showAuthorizedDevicesSheet = false
    @State private var selectedDeviceUUID: String = ""
    
    var body: some View {
        NavigationView {
            
            List(mc.authorizedDevices) { device in
                
                VStack(alignment: .leading) {
                    
                    Text(device.name)
                        .font(.headline)
                    Text("Autorizado el: \(formatDate(device.timestamp))")
                        .foregroundColor(Color.gray)
                        .font(.subheadline)
                    Text("RSSI: \(device.rssi, specifier: "%.1f") dBm")
                                            .foregroundColor(.gray)
                    Button(""){ showAuthorizedDevicesSheet = true
                        selectedDeviceUUID = mc.authorizedDevices[0].id.uuidString
                     

                    }
                }
            }
            .navigationTitle("Dispositivos Autorizados")
            
        }.fullScreenCover(isPresented: $showAuthorizedDevicesSheet) {
            AuthorizedDevicesSheet(authorizedDevices: mc.authorizedDevices)
        }  .environmentObject(mc)
    }
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct EnterPinView: View {
    @State private var enteredPin: String = ""
    @EnvironmentObject var mc: NotView

    var body: some View {
        VStack {
            Text("Ingrese PIN 1234")
                .font(.headline)
            
            TextField("PIN", text: $enteredPin)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .keyboardType(.numberPad)
            
            Button(action: {
                mc.verifyPin(enteredPin) // Llamada para verificar el PIN
            }) {
                Text("Verificar")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        
        .alert(isPresented: $mc.showAlert) {
            Alert(
                title: Text("Alerta"),
                message: Text(mc.alertMessage),
                dismissButton: .default(Text("OK")) {
                   print ("")
                    
                }
            )
        }
    }
}
struct IntruderListView: View {
    @EnvironmentObject var mc: NotView
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showCustomAlert = false
    @State private var showHelButton = true
    @Binding var showIntruderList: Bool
    
    var body: some View {
       
        List {

            ForEach(mc.intruders) { intruder in
                ZStack(alignment: .leading) {
                    
                    VStack{
                        if showHelButton {
                           
                            Text(intruder.name)
                            
                                .font(.headline)
                            Text("Detectado: \(formatDate(intruder.timestamp))")
                                .font(.subheadline)
                            if intruder.rssi != 0 {
                                Text("RSSI: \(intruder.rssi) dBm")
                                    .font(.subheadline)
                            }
                                                   Button("Autorizar") {
                                                    
                                                      // showIntruderList = false
                                                       mc.uuidToAuthorize = intruder.id
                                                                    
                                                                               DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                                                   mc.isShowingPinView = true
                                                                               }
                                                       
                                                      
                                                   }
                        }else{Text("Autorizado").foregroundColor(Color.green)}
                      
                    } 
                }
            }
        }
        .navigationTitle("Intrusos Detectados")
        .overlay(
            Group {
                if showCustomAlert {
                    CustomAlertView(isPresented: $showCustomAlert, message: mc.alertMessage)
                }
                  
            }
        )
        
        .onChange(of: mc.intruders) { newValue in
          showIntruderList = false
          
        }
    
        .environmentObject(mc)
        .sheet(isPresented: $mc.isShowingPinView) {
            EnterPinView()
                .environmentObject(mc)
        }
    }
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
  
}
    
    

struct EscanearView: View{
    var opciones:String
    @EnvironmentObject var mc: NotView
    @State private var showCustomAlert = false
    var body:some View{

        @State var Btscan :Bool = false
        ZStack{
           
            VStack{
           
              
               NetworkView()
                   
                
            }
            .overlay(
                Group {
                    
                    if showCustomAlert {
                        CustomAlertView(isPresented: $showCustomAlert, message: mc.alertMessage)
                    }
                }
            )
            .onChange(of: mc.intruders) { newValue in
          showCustomAlert = true
             
            }
            
            .environmentObject(mc)
           
        }
    }
}

struct ContentView: View {
    
    @State private var showIntruderList = false
    @State private var message = ""
    @StateObject var mc = NotView()
    
    var body: some View {
        
        NavigationView {
           
            HStack(spacing:20){
                
                Button(action: {
                 
                                   showIntruderList = true
                    
                                    }) {
                                    let color = mc.intruders.isEmpty ? Color(UIColor.systemRed) : Color(UIColor.systemGray)
                                        Image(systemName: "lock.open.laptopcomputer")
                                            .font(.system(size: 30))
                                            .padding()
                                            .background(color)
                                            .foregroundColor(.white)
                                            .clipShape(Circle())
                                    }
                
                                    .padding()
               
                    .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                NavigationLink(destination: EscanearView(opciones: "escanear")){
                 
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .padding()
                        .border(.clear)
                        .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(.blue, lineWidth: 12))
                        .background(Color.clear)
                       
                  
                    
                }.sheet(isPresented: $showIntruderList) {
                    NavigationView {
                        IntruderListView(showIntruderList: $showIntruderList)

                    }
                }
                NavigationLink(destination: AuthorizedDevicesView()) {
                
                    Image(systemName: "lock.laptopcomputer")
                        .font(.system(size: 30))
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
               
            }.background(
                Image("backg")
                    .opacity(0.3)
            )
           
            .navigationBarTitle("Nodos", displayMode: .inline)
                
             
                   .edgesIgnoringSafeArea(.all)
               
        }

      
          
       
            
        }
      
     
    }
    


#Preview {
    ContentView()
}
