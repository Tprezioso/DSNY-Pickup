//
//  LottieView.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 2/3/23.
//
 
import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    var name: String
    var loopMode: LottieLoopMode = .playOnce
    var contentMode: UIView.ContentMode = .scaleAspectFit
    @Binding var isShowing: Bool
    let animationView = LottieAnimationView()

    func makeUIView(context: UIViewRepresentableContext<LottieView>) -> UIView {
        let view = UIView()
        view.subviews.forEach({ $0.removeFromSuperview() })
       
        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)

        NSLayoutConstraint.activate([
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor),
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])

        animationView.animation = LottieAnimation.named(name)
        animationView.contentMode = contentMode
        animationView.loopMode = loopMode
        return view
    }

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<LottieView>) {        
        animationView.play { (finished) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.isShowing = false
                animationView.removeFromSuperview()
            }
        }
    }
}
