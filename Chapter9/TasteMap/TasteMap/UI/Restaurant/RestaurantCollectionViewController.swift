//
//  RestaurantCollectionViewController.swift
//  TasteMap
//
//  Created by Kevin McNeish on 9/14/24.
//

import UIKit

class RestaurantCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, RestaurantEditDelegate {
    
    var restaurants = [RestaurantEntity]()
    
    var traitChangesObserver: NSObjectProtocol?
    
    @IBOutlet weak var btnLocation: UIButton!
    @IBOutlet weak var restaurantCollectionView: UICollectionView!
    @IBOutlet weak var btnAdd: UIBarButtonItem!
    
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
        self.restaurants = Restaurant.shared.getAllEntities()
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
            self.restaurantCollectionView.reloadData()
        }
        self.restaurants = Restaurant.shared.getAllEntities()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        Location.shared.stopUpdatingLocation() // Stop updates when the view disappears
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AddRestaurantSegue", let editVC = segue.destination as? RestaurantEditTableViewController {
            editVC.delegate = self
            editVC.isNewRestaurant = true
        }
        else if segue.identifier == "EditRestaurantSegue", let editVC = segue.destination as? RestaurantEditTableViewController, let selectedRestaurant = sender as? RestaurantEntity {
            // Pass the selected RestaurantEntity to the edit view controller
            editVC.restaurantEntity = selectedRestaurant
            editVC.delegate = self
            editVC.isNewRestaurant = false
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        // Get the selected restaurant entity
        let selectedRestaurant = restaurants[indexPath.row]
        
        // Trigger the segue and pass the selected restaurant entity
        performSegue(withIdentifier: "EditRestaurantSegue", sender: selectedRestaurant)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.restaurants.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "RestaurantCell",
            for: indexPath) as! RestaurantCell
                    
        // Configure the cell
        let restaurantEntity = restaurants[indexPath.row]
        
        // Get the distance from the current location
        var distanceText: String? = nil
        if let latitude = restaurantEntity.latitude,
            let longitude = restaurantEntity.longitude {
            distanceText = Location.shared.distanceFromCurrentLocation(to: latitude, longitude: longitude)
        }
        
        // Set cuisine and distance information
        let cuisineText = restaurantEntity.cuisine?.name
        let combinedText = [cuisineText, distanceText].compactMap { $0 }.joined(separator: " - ")
        cell.lblCuisine.text = combinedText
        
        cell.lblName.text = restaurantEntity.name
        cell.lblAddress.text = restaurantEntity.fullAddress
        cell.lblNeighborhood.text = restaurantEntity.neighborhood
        
        let (statusText, isOpen) = Restaurant.shared.getOperatingHoursText(hours: restaurantEntity.hours)
                    
        // Get the operating hours text
        let attributedString = NSMutableAttributedString(string: statusText, attributes: [.foregroundColor: UIColor.label])
        
        // Apply color to the first word based on whether the restaurant is open or closed
        if let isOpen = isOpen {
            let firstWordRange = (statusText as NSString).range(of: statusText.components(separatedBy: " ")[0])
            let darkerGreenColor = UIColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0) // Darker green
            let statusColor: UIColor = isOpen ? darkerGreenColor : UIColor.red
            attributedString.addAttribute(.foregroundColor, value: statusColor, range: firstWordRange)
        }
        
        // Set the attributed string to the label
        cell.lblHours.attributedText = attributedString
        
        // Fetch the photos from the restaurant and its related meals
        var photos = [Data]()
        
        // Add the restaurant photo if available
        if let restaurantPhoto = restaurantEntity.photo {
            photos.append(restaurantPhoto)
        }
        
        // Add photos from related meals
        let meals = Meal.shared.getMeals(for: restaurantEntity)
        for meal in meals {
            if let mealPhoto = meal.photo {
                photos.append(mealPhoto)
            }
        }
        
        // Pass the photos to the cell's internal collection view
        cell.photos = photos
        cell.photoCollectionView.reloadData() // Reload the internal collection view
                    
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
    
    func didAddNewRestaurant(_ restaurant: RestaurantEntity) {
        self.restaurants.append(restaurant)
        self.restaurantCollectionView.reloadData()
    }

}

