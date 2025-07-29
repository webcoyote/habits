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
            backgroundView
            debugLabel
            effectView
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
            .opacity(showEffect ? 1 : 0)
            .animation(.easeIn(duration: 0.2), value: showEffect)
    }
    
    @ViewBuilder
    private var debugLabel: some View {
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
    }
    
    @ViewBuilder
    private var effectView: some View {
        VortexViewReader { proxy in
            effectContent
                .onAppear {
                    showEffect = true
                    if effect == .confetti || effect == .fireworks || effect == .magic {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            proxy.burst()
                        }
                    }
                }
        }
    }
    
    @ViewBuilder
    private var effectContent: some View {
        switch effect {
        case .confetti:
            confettiEffect
        case .fire:
            fireEffect
        case .fireworks:
            fireworksEffect
        case .magic:
            magicEffect
        case .snow:
            snowEffect
        case .rain:
            rainEffect
        case .smoke:
            smokeEffect
        case .fireflies:
            firefliesEffect
        }
    }
    
    @ViewBuilder
    private var confettiEffect: some View {
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
    }
    
    @ViewBuilder
    private var fireEffect: some View {
        VortexView(.fire) {
            Circle()
                .fill(.white)
                .frame(width: 32)
                .blur(radius: 3)
                .blendMode(.plusLighter)
                .tag("circle")
        }
    }
    
    @ViewBuilder
    private var fireworksEffect: some View {
        VortexView(.fireworks) {
            Circle()
                .fill(.white)
                .frame(width: 32)
                .blur(radius: 5)
                .blendMode(.plusLighter)
                .tag("circle")
        }
    }
    
    @ViewBuilder
    private var magicEffect: some View {
        VortexView(.magic) {
            Image(systemName: "sparkle")
                .foregroundColor(.white)
                .tag("sparkle")
        }
    }
    
    @ViewBuilder
    private var snowEffect: some View {
        VortexView(.snow) {
            Circle()
                .fill(.white)
                .frame(width: 8)
                .blur(radius: 1)
                .tag("circle")
        }
    }
    
    @ViewBuilder
    private var rainEffect: some View {
        VortexView(.rain) {
            Circle()
                .fill(.white)
                .frame(width: 32)
                .tag("circle")
        }
    }
    
    @ViewBuilder
    private var smokeEffect: some View {
        VortexView(.smoke) {
            Circle()
                .fill(.white)
                .frame(width: 64)
                .blur(radius: 20)
                .opacity(0.3)
                .tag("circle")
        }
    }
    
    @ViewBuilder
    private var firefliesEffect: some View {
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

