//
//  StartRidePopupVC.swift
//  Ride
//
//  Created by Rishabh Sharma on 12/09/24.
//

import UIKit

protocol PopupProtocol: AnyObject {
    func startRide()
}

class StartRidePopupVC: UIViewController {

    // MARK: Outlets
    @IBOutlet private weak var popupView: UIView!
    @IBOutlet private weak var popupLabel: UILabel!
    @IBOutlet private weak var startButton: UIButton!
    
    // MARK: Properties
    weak var popupDelegate: PopupProtocol?
    
    // MARK: Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        popupView.layer.cornerRadius = 12
    }
    
    // MARK: Action
    @IBAction func startButton(_ sender: Any) {
        self.dismiss(animated: true) { [weak self] in
            self?.popupDelegate?.startRide()
        }
    }
}
