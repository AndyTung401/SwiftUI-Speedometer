## Description
A app that shows your iPhone GPS data.

## Key Features
- Heading azimuth, Location coordinates (Lat&Lon), Speed, Acceleration, Accuracy
- Compass animation
- Speed/Acceleration graph with changable duration
- Tap on the speed or the acceleration to change unit (Speed: km/h, m/s; Acceleration: km/h*s, m/s^2)

Speedometer | Chart
| :---:  | :---: |
![3DE54853-D5D9-4A1B-ADF4-961C398E8E32](https://github.com/AndyTung401/SwiftUI-Speedometer/assets/109213867/41fd808d-b278-4a2a-8c83-8ad3ba6ab09d) | ![1BBC5FBC-3760-4D96-A9A4-C3D5F82F9517](https://github.com/AndyTung401/SwiftUI-Speedometer/assets/109213867/79c2d89c-a1f4-4ae3-ac6c-e8d48514a0e9)

## Acceleration
Acceleration can be acquired by either calculation of speed changes or device motion data (CoreMotion)

## Graph
The graph is rendered by SwiftUI Charts. 
The speed, acceleration data will be saved in a temporary array whose length is determined by a slider in order to send to the chart.

## References
The CoreLocation codes refers to [Andrew11US/AF-Swift-Tutorials](https://github.com/Andrew11US/AF-Swift-Tutorials/blob/main/core-location/core-location/ContentView.swift) and the CoreMotion codes refers to [Asperi's answer](https://stackoverflow.com/questions/62020407/swiftui-and-core-motion) on stack overflow.
