//
//  RestaurantCollectionViewController.swift
//  TasteMap
//
//  Created by Kevin McNeish on 9/14/24.
//

import UIKit

class RestaurantCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    let restaurants = ["Indian Flavours",
                           "Deli, Deli",
                           "O Valentin"]
    
    var traitChangesObserver: NSObjectProtocol?
    
    @IBOutlet weak var btnLocation: UIButton!
    @IBOutlet weak var restaurantCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        restaurantCollectionView.dataSource = self
        restaurantCollectionView.delegate = self
        
        // Register for trait changes
        traitChangesObserver = traitCollection.observe(\.verticalSizeClass, options: [.new]) { [weak self] _, change in
            guard let self = self else { return }
            self.restaurantCollectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    deinit {
        // Unregister trait change observer
        if let observer = traitChangesObserver {
            NotificationCenter.default.removeObserver(observer)
        }
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
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.restaurants.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "RestaurantCell",
            for: indexPath) as! RestaurantCell
                    
        // Configure the cell
        cell.lblName.text = restaurants[indexPath.row]
                    
        return cell
    }
    
    // UICollectionViewDelegateFlowLayout method
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width // Full width of the collection view
        let height: CGFloat = 310.0 // Fixed height for your cell
        
        return CGSize(width: width, height: height)
    }

    // Handle layout invalidation on orientation changes (viewWillTransition)
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // Invalidate layout on orientation change
        coordinator.animate(alongsideTransition: { context in
            self.restaurantCollectionView.collectionViewLayout.invalidateLayout()
        }, completion: nil)
    }

}

