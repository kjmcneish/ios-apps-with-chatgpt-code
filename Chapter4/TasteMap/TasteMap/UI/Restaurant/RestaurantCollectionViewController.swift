//
//  RestaurantCollectionViewController.swift
//  TasteMap
//
//  Created by Kevin McNeish on 9/14/24.
//

import UIKit

class RestaurantCollectionViewController: UIViewController {
    @IBOutlet weak var btnLocation: UIButton!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Location.shared.startUpdatingLocation { location, error in
            if let location = location, let city = location.city, let country = location.country {
                self.btnLocation.setTitle("\(city), \(country)", for: .normal)
            }
            else {
                // Handle the case where city or country is nil
                self.btnLocation.setTitle("Location not available", for: .normal)
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        Location.shared.stopUpdatingLocation() // Stop updates when the view disappears
    }

}

