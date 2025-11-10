//
//  ViewController.swift
//  BezierRope
//
//  Created by Samar Singh on 10/11/25.
//

import UIKit
import CoreMotion

class ViewController: UIViewController {
    private var bezierView: BezierRopeView!

    override func loadView() {
        view = UIView()
        view.backgroundColor = .black
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        bezierView = BezierRopeView(frame: view.bounds)
        bezierView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(bezierView)

        let infoLabel = UILabel()
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.textColor = .white
        infoLabel.font = .systemFont(ofSize: 12, weight: .medium)
        infoLabel.numberOfLines = 0
        infoLabel.text = "Move device (or drag points) — P0 & P3 fixed. P1 & P2 are springy."
        view.addSubview(infoLabel)
        NSLayoutConstraint.activate([
            infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            infoLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            infoLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -12)
        ])

        bezierView.start()
    }

    override var prefersStatusBarHidden: Bool { true }
}


