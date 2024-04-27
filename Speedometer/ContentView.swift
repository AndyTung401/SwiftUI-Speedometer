//
//  ContentView.swift
//  Location DataView
//
//  Created by 董承威 on 2024/2/7.
//


import SwiftUI
import Charts
import CoreLocation
import CoreMotion

class LocationViewModel: NSObject, ObservableObject {
    private var locationManager: CLLocationManager?
    @Published var speed = Double.zero
    @Published var lat = Double.zero
    @Published var lon = Double.zero
    @Published var alt = Double.zero
    @Published var azi = Double.zero
    @Published var horizontalAccuracy = Double.zero
    @Published var speedAccuracy = Double.zero
    @Published var headingAccuracy = Double.zero
    @Published var log: String?
    
    init(locationManager: CLLocationManager = CLLocationManager()) {
        super.init()
        self.locationManager = locationManager
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
}

extension LocationViewModel: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined:
            log = "Location authorization not determined"
        case .restricted:
            log = "Location authorization restricted"
        case .denied:
            log = "Location authorization denied"
        case .authorizedAlways:
            manager.startUpdatingLocation()
            manager.startUpdatingHeading()
        case .authorizedWhenInUse:
            manager.startUpdatingLocation()
            manager.startUpdatingHeading()
        @unknown default:
            log = "Unknown authorization status"
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.azi = newHeading.trueHeading
        self.headingAccuracy = newHeading.headingAccuracy
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locations.forEach { location in
            self.speed = location.speed
            self.lat = location.coordinate.latitude
            self.lon = location.coordinate.longitude
            self.alt = location.altitude
            self.horizontalAccuracy = location.horizontalAccuracy
            self.speedAccuracy = location.speedAccuracy
        }
    }
}

public func degreeFormatter(_ input: Double) -> String{
    let input = abs(input)
    let degree = String(format: "%.0f", floor(input))
    let minute = String(format: "%.0f", floor(fmod(input, 1)*60))
    let second = String(format: "%.0f", fmod(fmod(input, 1)*60, 1)*60)
    return String("""
\(degree)º\(minute)’\(second)”
""")
}

struct SpeedometerGaugeStyle: GaugeStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(Color(.systemGray5), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(135))
            Circle()
                .trim(from: 0, to: 0.75*configuration.value)
                .stroke(AngularGradient(colors: [.blue, .cyan], center: .center, angle: .degrees(-5)), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(135))
            VStack {
                Spacer()
                HStack {
                    configuration.minimumValueLabel
                        .frame(width: 80, alignment: .leading)
                    Spacer()
                    configuration.maximumValueLabel
                        .frame(width: 80, alignment: .trailing)
                }
                .frame(width: 160, height: 55, alignment: .top)
            }
        }
        .frame(width: 300, height: 300)
    }
}

func maximumSpeed(_ unit: Int, _ speedometerScale: Int) -> Int {
    if unit == 0 {
        switch speedometerScale {
        case 0:
            return 50
        case 1:
            return 100
        case 2:
            return 150
        default:
            return 200
        }
    } else if unit == 1 {
        switch speedometerScale {
        case 0:
            return 15
        case 1:
            return 30
        case 2:
            return 40
        default:
            return 50
        }
    } else {
        switch speedometerScale {
        case 0:
            return 25
        case 1:
            return 50
        case 2:
            return 100
        default:
            return 150
        }
    }
}

func speedUnitConverter(_ unit: Int, _ speed/*m/s*/: Double) -> Double {
    switch unit {
    case 0:
        return speed*3.6
    case 1:
        return speed
    default:
        return speed*2.2369362921
    }
}

func speedUnit(_ unit: Int) -> String {
    switch unit {
    case 0:
        return "km/h"
    case 1:
        return "m/s"
    default:
        return "mph"
    }
}

struct ContentView: View {
    @State private var unit: Int = 0 //0:kmh, 1:m/s, 2:mph
    @ObservedObject private var locationViewModel = LocationViewModel()
    let motionManager = CMMotionManager()
    let queue = OperationQueue()
    @State private var acceleration = Double.zero
    @State private var deltaSpeed = Double.zero
    @State private var lastSpeed = Double.zero {
        willSet{
            deltaSpeed = locationViewModel.speed - lastSpeed
        }
        didSet{
            if lastSpeed == locationViewModel.speed && lastSpeed == 0.0{
                deltaSpeed = 0
            }
        }
    }
    @State private var speedHistory = [Double.zero]
    @State private var accLocationHistory = [Double.zero]
    @State private var accMotionHistory = [Double.zero]
    @State private var chartLength = 300.0
    @State private var accChartUseMotion = false
    @State private var showSpeedChart = true
    @State private var speedometerScale: Int = 0 //0, 1, 2, 3
    
    var body: some View {
        TabView {
            ZStack {
                VStack {
                    VStack(spacing: 10) {
                        HStack {
                            Image(systemName: "safari").rotationEffect(Angle(degrees: -45-locationViewModel.azi))
                            Text("\(String(format:"%.1fº", locationViewModel.azi))")
                                .monospacedDigit()
                                .frame(width: 110, alignment: .trailing)
                            
                            Group{
                                switch locationViewModel.azi {
                                case 0 ..< 22.5:
                                    Text("NW")
                                case 22.5 ..< 67.5:
                                    Text("NE")
                                case 67.5 ..< 112.5:
                                    Text("E ")
                                case 112.5 ..< 157.5:
                                    Text("SE")
                                case 157.5 ..< 202.5:
                                    Text("S ")
                                case 202.5 ..< 247.5:
                                    Text("SW")
                                case 247.5 ..< 292.5:
                                    Text("W ")
                                case 292.5 ..< 337.5:
                                    Text("NW")
                                case 337.5 ... 360.0:
                                    Text("N ")
                                default:
                                    Text("")
                                }
                            }
                            .frame(width: 60, alignment: .leading)
                        }//compass hstack
                        .font(.system(size: 35))
                        .padding(.top)
                        
                        HStack(spacing: 15){
                            HStack(spacing: 0){
                                Text("\(degreeFormatter(locationViewModel.lat))")
                                Text(" \(locationViewModel.lat<0 ? "S" : "N")")
                            }//lat
                            .frame(width: 160, alignment: .trailing)
                            HStack(spacing: 0){
                                Text("\(degreeFormatter(locationViewModel.lon))")
                                Text(" \(locationViewModel.lon<0 ? "W" : "E")")
                            }//lon
                            .frame(width: 160, alignment: .leading)
                        }//coord hstack
                        .font(.system(size: 25))
                    }
                    .containerRelativeFrame(.vertical, count: 5, span: 1, spacing: 0)

                    Divider().overlay(Color(.systemGray)).padding(10).padding(.horizontal)
                    
                    VStack {
                        ZStack{
                            Gauge(value: speedUnitConverter(unit, locationViewModel.speed), in: 0...Double(maximumSpeed(unit, speedometerScale))) {
                                
                            } currentValueLabel: {
                                Text("")
                            } minimumValueLabel: {
                                Text("0")
                            } maximumValueLabel: {
                                Text("\(maximumSpeed(unit, speedometerScale))")
                            }
                            .gaugeStyle(SpeedometerGaugeStyle())
                            .animation(.bouncy(duration: 0.3), value: unit)
                            .animation(.bouncy(duration: 0.3), value: speedometerScale)
                            
                            VStack(spacing: 10){
                                HStack(spacing: 15){
                                    HStack(spacing: 3){
                                        Text("\(String(format: "%.1f", locationViewModel.speed<0 ? 0 : speedUnitConverter(unit, locationViewModel.speed)))")
                                            .font(.system(size: 60))
                                            .padding(.leading)
                                        Text(speedUnit(unit))
                                            .font(.system(size: 25))
                                            .offset(y: 7)
                                    }//km/h speed
                                }//speed hstack
                                .fontWeight(.semibold)
                            }
                            .padding()
                            .animation(.bouncy(duration: 0.3), value: unit)
                        }
                        .onTapGesture {
                            unit = (unit+1)%3
                        }
                        
                        Picker("", selection: $speedometerScale) {
                            Text("\(maximumSpeed(unit, 0))").tag(0)
                            Text("\(maximumSpeed(unit, 1))").tag(1)
                            Text("\(maximumSpeed(unit, 2))").tag(2)
                            Text("\(maximumSpeed(unit, 3))").tag(3)
                        }
                        .pickerStyle(.segmented)
                        .containerRelativeFrame(.horizontal, count: 4, span: 3, spacing: 0)
                    }
                    .containerRelativeFrame(.vertical, count: 7, span: 4, spacing: 0)
                    
                    Spacer()
                    
                    if locationViewModel.log != .none{
                        Text(locationViewModel.log ?? "")
                            .foregroundStyle(.red)
                            .lineLimit(1)
                            .minimumScaleFactor(0.1)
                            .padding()
                    }//location log
                }
                
                VStack {
                    Spacer()
                    if locationViewModel.horizontalAccuracy < 0 {
                        Text("Azimuth unavaliable")
                            .font(.system(size: 17))
                    } else {
                        HStack(spacing:3){
                            Text("Azimuth: ")
                            Image(systemName: "plusminus")
                            Text("\(String(format: "%.2f", locationViewModel.headingAccuracy))º")
                        }
                        .font(.system(size: 17))
                    }//Heading Acc
                    
                    if locationViewModel.horizontalAccuracy < 0 {
                        Text("Location unavaliable")
                            .font(.system(size: 17))
                    } else {
                        HStack(spacing:3){
                            Text("Location: ")
                            Image(systemName: "plusminus")
                            Text("\(String(format: "%.2f", locationViewModel.horizontalAccuracy)) m")
                        }
                        .font(.system(size: 17))
                    }//Location Acc
                    
                    if locationViewModel.speedAccuracy < 0 {
                        Text("Speed unavaliable")
                            .font(.system(size: 17))
                    } else {
                        HStack(spacing:3){
                            Text("Speed: ")
                            Image(systemName: "plusminus")
                            Text(String(format: "%.2f ", speedUnitConverter(unit, locationViewModel.speedAccuracy)))
                            Text(speedUnit(unit))
                        }
                        .font(.system(size: 17))
                    }//Speed Acc
                }//AccuracyStack
                .fontWeight(.regular)
                .opacity(0.8)
                .padding(.bottom)
                .animation(.bouncy(duration: 0.3), value: unit)
            }//Zstack
            .tabItem { Label("Speedometer", systemImage: "speedometer") }
            
            VStack {
                Group {
                    VStack(spacing: 10){
                        HStack(spacing: 15){
                            HStack(spacing: 3){
                                Text("\(String(format: "%.1f", locationViewModel.speed<0 ? 0 : speedUnitConverter(unit, locationViewModel.speed)))")
                                    .font(.system(size: 60))
                                    .padding(.leading)
                                Text(speedUnit(unit))
                                    .font(.system(size: 25))
                                    .offset(y: 7)
                            }//km/h speed
                        }//speed hstack
                        .fontWeight(.semibold)
                        
                        HStack(spacing:0){
                            HStack(spacing:0){
                                Text("\(deltaSpeed<0 ? "-" : " ")").frame(width: 10)
                                Text("\(String(format: "%.2f" , locationViewModel.speed<0 ? 0 : abs(speedUnitConverter(unit, deltaSpeed))))")
                                Text(" (")
                                Text("\(String(format: "%.1f" , speedUnitConverter(unit, acceleration*9.8)))")
                                    .frame(width:52, alignment: .trailing)
                                Image(systemName: "gyroscope").font(.system(size: 15)).padding(.bottom, 5)
                                Text(") ")
                            }
                            .frame(width: 175, alignment: .trailing)
                            HStack(spacing: 0){
                                Text(speedUnit(unit)+"·s")
//                                Text("\(usingKMH ? "km/h·s" : " m/s")")
//                                Text("\(usingKMH ? "" : "2")").font(.system(size: 15)).baselineOffset(9.0).fontWeight(.regular)
                            }
                            .frame(width: 80, alignment: .leading)
                        }//acc hstack
                    }
                    .padding()
                    .animation(.bouncy(duration: 0.3), value: unit)
                }//speed and acceleration
                .onTapGesture {
                    unit = (unit+1)%3
                }
                .padding()
                
                Divider().padding(10).padding(.horizontal).padding(.bottom)
                
                if showSpeedChart {
                    Chart{
                        ForEach(0..<speedHistory.count, id: \.self){
                            LineMark(
                                x: .value("x", $0),
                                y: .value("y", speedUnitConverter(unit, speedHistory[$0]))
                            )
                        }
                    }
                    .chartXScale(domain: 0...speedHistory.count)
                    .chartXAxis(.hidden)
                    .chartYAxis(.visible)
                    .padding()
                    .frame(width: 300, height: 250)
                } else {
                    VStack(spacing:10){
                        if !accChartUseMotion {
                            Chart{
                                ForEach(0..<accLocationHistory.count, id: \.self){
                                    LineMark(
                                        x: .value("x", $0),
                                        y: .value("y", speedUnitConverter(unit, accLocationHistory[$0]))
                                    )
                                }
                            }
                            .chartXScale(domain: 0...speedHistory.count)
                            .chartXAxis(.hidden)
                            .chartYAxis(.visible)
                            .padding()
                            .frame(width: 300)
                        } else {
                            Chart{
                                ForEach(0..<accMotionHistory.count, id: \.self){
                                    LineMark(
                                        x: .value("x", $0),
                                        y: .value("y", speedUnitConverter(unit, accMotionHistory[$0]))
                                    )
                                }
                            }
                            .chartXScale(domain: 0...accMotionHistory.count)
                            .chartXAxis(.hidden)
                            .chartYAxis(.visible)
                            .padding()
                            .frame(width: 300)
                        }
                        
                        HStack(spacing:0){
                            Text("Based on: ").font(.body)
                            Picker("", selection: $accChartUseMotion){
                                Text("CLLocation").tag(false)
                                Text("CLMotion").tag(true)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 200, height: 45)
                        }
                    }.frame(height: 250)
                }//graph
                
                HStack(spacing:0) {
                    Picker("", selection: $showSpeedChart){
                        Text("Speed").tag(true)
                        Text("Acceleration").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 300)
                    .padding(.bottom)
                }//graph mode picker
                
                Group{
                    Slider(value: $chartLength, in: 300...3000, step: 100){
                        Text("Chart Length")
                    } minimumValueLabel: {
                        Text("3s")
                    } maximumValueLabel: {
                        Text("30s")
                    }
                    .frame(width: 300)
                    Text("\(Int(chartLength/100))s").font(.title3).padding(.top, -5)
                }//slider
                .font(.body)
                
                VStack {
                    Spacer()
                    if locationViewModel.horizontalAccuracy < 0 {
                        Text("Azimuth unavaliable")
                            .font(.system(size: 17))
                    } else {
                        HStack(spacing:3){
                            Text("Azimuth: ")
                            Image(systemName: "plusminus")
                            Text("\(String(format: "%.2f", locationViewModel.headingAccuracy))º")
                        }
                        .font(.system(size: 17))
                    }//Heading Acc
                    
                    if locationViewModel.horizontalAccuracy < 0 {
                        Text("Location unavaliable")
                            .font(.system(size: 17))
                    } else {
                        HStack(spacing:3){
                            Text("Location: ")
                            Image(systemName: "plusminus")
                            Text("\(String(format: "%.2f", locationViewModel.horizontalAccuracy)) m")
                        }
                        .font(.system(size: 17))
                    }//Location Acc
                    
                    if locationViewModel.speedAccuracy < 0 {
                        Text("Speed unavaliable")
                            .font(.system(size: 17))
                    } else {
                        HStack(spacing:3){
                            Text("Speed: ")
                            Image(systemName: "plusminus")
//                            Text("\(usingKMH ? "\(String(format: "%.2f", locationViewModel.speedAccuracy*3.6)) km/h" : "\(String(format: "%.2f", locationViewModel.speedAccuracy)) m/s")")
                            Text(String(format: "%.2f ", speedUnitConverter(unit, locationViewModel.speedAccuracy)))
                            Text(speedUnit(unit))
                        }
                        .font(.system(size: 17))
                    }//Speed Acc
                }//AccuracyStack
                .fontWeight(.regular)
                .opacity(0.8)
                .padding(.bottom)
            }
            .tabItem { Label("Chart", systemImage: "chart.xyaxis.line") }
        }
        .monospacedDigit()
        .font(.system(size: 25))
        .fontWeight(.light)
        .opacity(0.9)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGray6).opacity(0.7))
        .onAppear
        {
            self.motionManager.startDeviceMotionUpdates(to: self.queue) { (data: CMDeviceMotion?, error: Error?) in
                guard let data = data else { return }
                let acceleration: CMAcceleration = data.userAcceleration
                DispatchQueue.main.async {
                    self.acceleration = pow(pow(acceleration.x,2)+pow(acceleration.y, 2)+pow(acceleration.z, 2),0.5)
                    if lastSpeed != locationViewModel.speed && locationViewModel.speed >= 0{
                        lastSpeed = locationViewModel.speed
                    }
                    
                    self.speedHistory.append(locationViewModel.speed >= 0 ? locationViewModel.speed : 0)
                    self.accLocationHistory.append(self.deltaSpeed)
                    self.accMotionHistory.append(self.acceleration*9.8)
                    if speedHistory.count >= Int(chartLength){
                        self.speedHistory.removeFirst()
                        self.accLocationHistory.removeFirst()
                        self.accMotionHistory.removeFirst()
                        if speedHistory.count > Int(chartLength){
                            self.speedHistory.removeFirst()
                            self.accLocationHistory.removeFirst()
                            self.accMotionHistory.removeFirst()
                        }
                    }
                }
            }
        }//.onappear
    }
}


#Preview {
    ContentView()
}
