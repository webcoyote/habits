import SwiftUI
import Vortex

enum CelebrationEffect: CaseIterable {
    case confetti
    case fire
    case fireworks
    case magic
    case snow
    case rain
    case smoke
    case fireflies
    
    static func random() -> CelebrationEffect {
        allCases.randomElement() ?? .confetti
    }
    
    func next() -> CelebrationEffect {
        let allCases = CelebrationEffect.allCases
        guard let currentIndex = allCases.firstIndex(of: self) else {
            return allCases.first ?? .confetti
        }
        let nextIndex = (currentIndex + 1) % allCases.count
        return allCases[nextIndex]
    }
}

struct CelebrationEffectView: View {
    let effect: CelebrationEffect
    @State private var showEffect = false
    
    var body: some View {
        ZStack {
            // Semi-transparent background for better visibility
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .opacity(showEffect ? 1 : 0)
                .animation(.easeIn(duration: 0.2), value: showEffect)
            
            // Debug label showing effect name
            VStack {
                Text("Effect: \(String(describing: effect))")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    .padding(.top, 60)
                
                Spacer()
            }
            .zIndex(2)
            
            VortexViewReader { proxy in
                Group {
                    switch effect {
                    case .confetti:
                        VortexView(.confetti) {
                            Rectangle()
                                .fill(.white)
                                .frame(width: 16, height: 16)
                                .tag("square")
                            
                            Circle()
                                .fill(.white)
                                .frame(width: 16)
                                .tag("circle")
                        }
                        
                    case .fire:
                        VortexView(.fire) {
                            Circle()
                                .fill(.white)
                                .frame(width: 32)
                                .blur(radius: 3)
                                .blendMode(.plusLighter)
                                .tag("circle")
                        }
                        
                    case .fireworks:
                        VortexView(.fireworks) {
                            Circle()
                                .fill(.white)
                                .frame(width: 32)
                                .blur(radius: 5)
                                .blendMode(.plusLighter)
                                .tag("circle")
                        }
                        
                    case .magic:
                        VortexView(.magic) {
                            Image(systemName: "sparkle")
                                .foregroundColor(.white)
                                //.blendMode(.plusLighter)
                                .tag("sparkle")
                        }
                        
                    case .snow:
                        VortexView(.snow) {
                            Circle()
                                .fill(.white)
                                .frame(width: 8)
                                .blur(radius: 1)
                                .tag("circle")
                        }
                        
                    case .rain:
                        VortexView(.rain) {
                            Circle()
                                .fill(.white)
                                .frame(width: 32)
                                .tag("circle")
                        }
                        
                    case .smoke:
                        VortexView(.smoke) {
                            Circle()
                                .fill(.white)
                                .frame(width: 64)
                                .blur(radius: 20)
                                .opacity(0.3)
                                .tag("circle")
                        }
                        
                    case .fireflies:
                        VortexView(.fireflies) {
                            Circle()
                                .fill(Color.yellow)
                                .frame(width: 12)
                                .blur(radius: 4)
                                .blendMode(.plusLighter)
                                .tag("circle")
                        }
                    }
                }
                .onAppear {
                    showEffect = true
                    // Trigger burst effects for certain types
                    if effect == .confetti || effect == .fireworks || effect == .magic {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            proxy.burst()
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

