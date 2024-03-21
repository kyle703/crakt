//
//  LoadingView.swift
//  crakt
//
//  Created by Kyle Thompson on 9/28/23.
//

import SwiftUI


struct LoadingView: View {
    @State private var animateRock = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            // Crescent moons and pipes
            ForEach(0..<10) { _ in
                
                CrescentMoon()
                    .frame(width: 100)
                    .position(x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                              y: CGFloat.random(in: 0...UIScreen.main.bounds.height))
                
            }
            
            
            ForEach(0..<10) { _ in

                
                PipeView()
                    .foregroundColor(Color.random)
                    .position(x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                              y: CGFloat.random(in: 0...UIScreen.main.bounds.height))
                
                
                         
            }
            
            // Rock emoji with animation
            Text("🪨")
                .font(.system(size: 100))
                .scaleEffect(animateRock ? 2 : 1)
                .animation(
                    Animation.easeInOut(duration: 0.5)
                        .repeatCount(3, autoreverses: true)
                )
                .onAppear() {
                    animateRock.toggle()
                }
            
            // "Crakt" text
            Text("Crakt")
                .font(.custom("Futura", size: 50)) // Replace "YourFontName" with your desired font
                .foregroundColor(.white)
                .offset(y: 60)
        }
    }
}

func CrescentMoonShapeMask(in rect: CGRect) -> Path {
    var shape = Path()

    // Add the larger circle path
    shape.addPath(Circle().path(in: CGRect(x: 2, y: 0, width: rect.width, height: rect.height)))

    // Offset for the smaller circle to cut out
    let smallerCircleOffset = rect.width * 0.2
    let smallerCircleRect = CGRect(x: smallerCircleOffset, y: 0, width: rect.width, height: rect.height)
    
    // Add the smaller circle path
    shape.addPath(Circle().path(in: smallerCircleRect))

    return shape
}

struct CrescentMoon: View {
    let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
    var body: some View {
        // The larger circle representing the full moon
        Circle()
            .fill(Color.yellow)
            .frame(width: rect.width, height: rect.height)
            // Apply the mask created by the CrescentMoonShapeMask
            .mask(CrescentMoonShapeMask(in: rect).fill(style: FillStyle(eoFill: true)))
            // Optional shadow for styling
        
    }
}
extension Color {
    static var random: Color {
        return Color(
            red: Double.random(in: 0...1),
            green: Double.random(in: 0...1),
            blue: Double.random(in: 0...1)
        )
    }
}


struct Pipe: Shape {
    let segments: [CGRect]
    
    init() {
            var tempSegments: [CGRect] = []
            let numberOfTurns = Int.random(in: 5...8)
            let pipeWidth = CGFloat.random(in: 5...20)
            let startingPoint = CGPoint(x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height))
            
            var currentPoint = startingPoint
            var isHorizontal = Bool.random() // Initial random direction
            
            for _ in 0..<numberOfTurns {
                let nextPoint: CGPoint
                if isHorizontal {
                    nextPoint = CGPoint(x: CGFloat.random(in: 0...UIScreen.main.bounds.width), y: currentPoint.y)
                } else {
                    nextPoint = CGPoint(x: currentPoint.x, y: CGFloat.random(in: 0...UIScreen.main.bounds.height))
                }
                
                let segment = CGRect(x: min(currentPoint.x, nextPoint.x),
                                     y: min(currentPoint.y, nextPoint.y),
                                     width: abs(currentPoint.x - nextPoint.x) + pipeWidth,
                                     height: abs(currentPoint.y - nextPoint.y) + pipeWidth)
                tempSegments.append(segment)
                
                currentPoint = nextPoint
                isHorizontal.toggle() // Switch direction for the next segment
            }
            
            self.segments = tempSegments
        }
    
    
        
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        for segment in segments {
            path.addRoundedRect(in: segment, cornerSize: CGSize(width: segment.width/2, height: segment.width/2))
        }
        
        return path
    }
}

struct PipeView: View {
    let pipe: Pipe
    let pipeColor: Color
    let darkerPipeColor: Color

    
    init() {
        self.pipe = Pipe()
        self.pipeColor = Color.randomFromSet
        self.darkerPipeColor = pipeColor.darken(by: 0.2)
    }
    
    var body: some View {
        ZStack {
            ForEach(pipe.segments.indices, id: \.self) { index in
                let segment = pipe.segments[index]
                let isHorizontal = segment.width > segment.height
                let gradient = LinearGradient(gradient: Gradient(colors: [darkerPipeColor, pipeColor]),
                                              startPoint: !isHorizontal ? .leading : .top,
                                              endPoint: !isHorizontal ? .trailing : .bottom)
                RoundedRectangle(cornerRadius: segment.width/2)
                    .fill(gradient)
                    .frame(width: segment.width, height: segment.height)
                    .position(x: segment.midX, y: segment.midY)
            }
        }
    }
}

extension Color {
    static var randomFromSet: Color {
        let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]
        return colors.randomElement() ?? .white
    }
    
    func rgba() -> (red: Double, green: Double, blue: Double, opacity: Double)? {
        let description = "\(self)"
        
        let scanner = Scanner(string: description)
        scanner.scanUpToCharacters(from: CharacterSet.decimalDigits, into: nil)
        
        var red: Double = 0, green: Double = 0, blue: Double = 0, opacity: Double = 0
        
        scanner.scanDouble(&red)
        scanner.scanDouble(&green)
        scanner.scanDouble(&blue)
        scanner.scanDouble(&opacity)
        
        return (red, green, blue, opacity)
    }
    
    func darken(by percentage: Double) -> Color {
        guard let rgba = self.rgba() else { return self }
        
        return Color(red: max(rgba.red - percentage, 0),
                     green: max(rgba.green - percentage, 0),
                     blue: max(rgba.blue - percentage, 0),
                     opacity: 10)
    }
}


struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}
