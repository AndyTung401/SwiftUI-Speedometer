## Description
A app that shows your iPhone GPS data.

## Key Features
- Heading azimuth, Location coordinates (Lat&Lon), Speed, Acceleration, Accuracy
- Compass animation
- Speed/Acceleration graph with changable duration
- Tap on the speed or the acceleration to change unit (Speed: km/h, m/s; Acceleration: km/h*s, m/s^2)

## Acceleration
Acceleration is acquired by both calculation of speed changes and device motion data (CoreMotion)

## Graph
The graph is rendered by SwiftUI Charts. 
The speed, acceleration data will be saved in a temporary array whose length is under control in order to send to the chart.
