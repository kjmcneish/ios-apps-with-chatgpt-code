//
//  ViewController.swift
//  TasteMap
//
//  Created by Kevin McNeish on 8/21/24.
//

import UIKit
import CoreLocation
import MapKit

enum SortOption {
    case name, distance, cuisine, neighborhood, mostRecentMeal
}

enum FilterOption {
    case none, openNow
}

class RestaurantViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, RestaurantCellDelegate {
        
    @IBOutlet weak var btnAdd: UIBarButtonItem!
    @IBOutlet weak var btnLocation: UIButton!
	@IBOutlet weak var restaurantCollectionView: UICollectionView!
	@IBOutlet weak var btnFilter: UIButton!
	
	var restaurants = [RestaurantEntity]()
    
    var traitChangesObserver: NSObjectProtocol?
    
    var currentSortOption: SortOption = .distance
    var currentFilterOption: FilterOption = .none
    var isEditingMode = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
				
		// Do any additional setup after loading the view.
		// Set the data source and delegate
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
            
            if self.currentSortOption == .distance {
                self.sortRestaurantsByDistance()
            }
            self.restaurantCollectionView.reloadData()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        Location.shared.stopUpdatingLocation() // Stop updates when the view disappears
    }

    // Handle layout invalidation on orientation changes (viewWillTransition)
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // Invalidate layout on orientation change
        coordinator.animate(alongsideTransition: { context in
            self.restaurantCollectionView.collectionViewLayout.invalidateLayout()
        }, completion: nil)
    }
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return self.restaurants.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RestaurantCell", for: indexPath) as! RestaurantCell
				
		// Configure the cell
		let restaurantEntity = restaurants[indexPath.row]
		cell.lblName.text = restaurantEntity.name
		
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
		
		cell.lblAddress.text = restaurantEntity.fullAddress
		cell.lblNeighborhood.text = restaurantEntity.neighborhood
        
        // Get the operating hours text
		let (statusText, isOpen) = Restaurant.shared.getOperatingHoursText(hours: restaurantEntity.hours)
					
        let attributedString = NSMutableAttributedString(string: statusText, attributes: [.foregroundColor: UIColor.secondaryText])
		
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
        
        // Add a tap gesture recognizer to the cell
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped(_:)))
        cell.addGestureRecognizer(tapGesture)
        cell.delegate = self
        cell.restaurant = restaurantEntity
        
        // Add delete button only if in editing mode
        if isEditingMode {
            let deleteButton = UIButton(type: .system)
            deleteButton.setTitle("Delete", for: .normal)
            deleteButton.setTitleColor(.red, for: .normal)
            deleteButton.frame = CGRect(x: cell.bounds.width - 80, y: cell.bounds.height - 40, width: 70, height: 30)
            deleteButton.tag = indexPath.row
            deleteButton.addTarget(self, action: #selector(deleteButtonTapped(_:)), for: .touchUpInside)
            cell.addSubview(deleteButton)
        } else {
            // Remove existing delete buttons
            for subview in cell.subviews where subview is UIButton {
                subview.removeFromSuperview()
            }
        }
        cell.btnDirections.isEnabled = !self.isEditingMode
        
		return cell
	}
	
	// UICollectionViewDelegateFlowLayout method
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		let width = collectionView.bounds.width // Full width of the collection view
		let height: CGFloat = 310.0 // Fixed height for your cell
		
		return CGSize(width: width, height: height)
	}
	
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        // Get the selected restaurant entity
        let selectedRestaurant = restaurants[indexPath.row]
        
        // Trigger the segue and pass the selected restaurant entity
        performSegue(withIdentifier: "EditRestaurantSegue", sender: selectedRestaurant)
    }
    
    @objc func cellTapped(_ sender: UITapGestureRecognizer) {
        
        if self.isEditingMode {
            return // Prevent navigation when in edit mode
        }
        
        if let tappedCell = sender.view as? UICollectionViewCell,
           let indexPath = restaurantCollectionView.indexPath(for: tappedCell) {
            let selectedRestaurant = restaurants[indexPath.row]
            // Perform the segue to RestaurantEditTableViewController
            performSegue(withIdentifier: "EditRestaurantSegue", sender: selectedRestaurant)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AddRestaurantSegue", let editVC = segue.destination as? RestaurantEditTableViewController {
            editVC.delegate = self
            editVC.isNewRestaurant = true
        }
        else if segue.identifier == "EditRestaurantSegue", let editVC = segue.destination as? RestaurantEditTableViewController, let selectedRestaurant = sender as? RestaurantEntity {
            // Pass the selected RestaurantEntity to the edit view controller
            editVC.restaurantEntity = selectedRestaurant
            editVC.isNewRestaurant = false
        }
    }

    // RestaurantCellDelegate method
    func didTapDirections(for restaurant: RestaurantEntity) {
        if let latitude = restaurant.latitude, let longitude = restaurant.longitude {
            openGoogleMaps(latitude: latitude, longitude: longitude)
        }
    }
    
    func openAppleMaps(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        let destinationCoordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let placemark = MKPlacemark(coordinate: destinationCoordinates)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "Restaurant"
        
        let options = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        mapItem.openInMaps(launchOptions: options)
    }
    
    func openGoogleMaps(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        if let url = URL(string: "comgooglemaps://?daddr=\(latitude),\(longitude)&directionsmode=driving") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:])
            } else {
                // Google Maps is not installed, open in Safari or Apple Maps instead
                openAppleMaps(latitude: latitude, longitude: longitude)
            }
        }
    }
    
    @IBAction func editButtonTapped(_ sender: Any) {
        // Toggle edit mode
        self.isEditingMode.toggle()
        
        self.btnAdd.isEnabled = !isEditingMode

        // Reload collection view to show/hide delete buttons
        restaurantCollectionView.reloadData()
    }
    
    @objc func deleteButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        let restaurantToDelete = restaurants[index]
        
        // Remove the restaurant entity from the list
        restaurants.remove(at: index)
        
        // Delete the entity from the data source
        let result = Restaurant.shared.deleteEntityAndSave(restaurantToDelete)
        
        if result.state == .saveComplete {
            restaurantCollectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
        }
        else {
            // Handle save errors (you can show an alert or print a message)
            let alert = UIAlertController(title: "Delete Error", message: "Failed to delete the restaurant. Please try again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func sortButtonTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Sort Restaurants", message: "Choose a sorting option", preferredStyle: .actionSheet)
        
        // Sort by Cuisine
        let cuisineAction = UIAlertAction(title: "Cuisine", style: .default, handler: { _ in
            self.restaurants.sort { ($0.cuisine?.name ?? "") < ($1.cuisine?.name ?? "") }
            self.currentSortOption = .cuisine
            self.restaurantCollectionView.reloadData()
        })
        if currentSortOption == .cuisine {
            cuisineAction.setValue(true, forKey: "checked")
        }
        alert.addAction(cuisineAction)
        
        // Sort by Distance
        let distanceAction = UIAlertAction(title: "Distance", style: .default, handler: { _ in
            self.sortRestaurantsByDistance()
            self.currentSortOption = .distance
        })
        if currentSortOption == .distance {
            distanceAction.setValue(true, forKey: "checked")
        }
        alert.addAction(distanceAction)
        
        // Sort by Most Recent Meal
        let mostRecentMealAction = UIAlertAction(title: "Most Recent Meal", style: .default, handler: { _ in
            self.restaurants.sort { (restaurant1: RestaurantEntity, restaurant2: RestaurantEntity) -> Bool in
                // Get the most recent meal for each restaurant
                let meal1 = Meal.shared.getMeals(for: restaurant1).sorted(by: { $0.dateTime > $1.dateTime }).first
                let meal2 = Meal.shared.getMeals(for: restaurant2).sorted(by: { $0.dateTime > $1.dateTime }).first
                
                // Compare based on the dateTimeCreated of the most recent meal or fallback to distantPast
                return (meal1?.dateTime ?? Date.distantPast) > (meal2?.dateTime ?? Date.distantPast)
            }
            self.currentSortOption = .mostRecentMeal
            self.restaurantCollectionView.reloadData()
        })

        if currentSortOption == .mostRecentMeal {
            mostRecentMealAction.setValue(true, forKey: "checked")
        }
        alert.addAction(mostRecentMealAction)
        
        // Sort by Name
        let nameAction = UIAlertAction(title: "Name", style: .default, handler: { _ in
            self.restaurants.sort { $0.name < $1.name }
            self.currentSortOption = .name
            self.restaurantCollectionView.reloadData()
        })
        if currentSortOption == .name {
            nameAction.setValue(true, forKey: "checked")
        }
        alert.addAction(nameAction)
        
        // Sort by Neighborhood
        let neighborhoodAction = UIAlertAction(title: "Neighborhood", style: .default, handler: { _ in
            self.restaurants.sort { ($0.neighborhood ?? "") < ($1.neighborhood ?? "") }
            self.currentSortOption = .neighborhood
            self.restaurantCollectionView.reloadData()
        })
        if currentSortOption == .neighborhood {
            neighborhoodAction.setValue(true, forKey: "checked")
        }
        alert.addAction(neighborhoodAction)
        
        // Cancel option
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        // For iPad compatibility (required for Action Sheets on iPads)
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = (sender as! UIButton).frame
        }
        
        // Present the action sheet
        self.present(alert, animated: true, completion: nil)
    }
    
    func sortRestaurantsByDistance() {
        self.restaurants.sort {
            guard let lat1 = $0.latitude, let lon1 = $0.longitude,
                  let lat2 = $1.latitude, let lon2 = $1.longitude else { return false }

            let distance1 = Location.shared.distanceFromCurrentLocation(to: lat1, longitude: lon1) ?? 0.0
            let distance2 = Location.shared.distanceFromCurrentLocation(to: lat2, longitude: lon2) ?? 0.0

            return distance1 < distance2
        }
        self.restaurantCollectionView.reloadData()
    }

    @IBAction func filterButtonTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Filter Restaurants", message: "Choose a filter option", preferredStyle: .actionSheet)
        
        // Filter by Open Now
        let openNowAction = UIAlertAction(title: "Open Now", style: .default, handler: { _ in
            self.restaurants = Restaurant.shared.getAllEntities().filter { restaurant in
                let (_, isOpen) = Restaurant.shared.getOperatingHoursText(hours: restaurant.hours)
                return isOpen == true
            }
            self.currentFilterOption = .openNow
            self.restaurantCollectionView.reloadData()
        })
        if currentFilterOption == .openNow {
            openNowAction.setValue(true, forKey: "checked")
        }
        alert.addAction(openNowAction)
        
        // Clear Filter
        let clearFilterAction = UIAlertAction(title: "Clear Filter", style: .default, handler: { _ in
            self.restaurants = Restaurant.shared.getAllEntities() // Reset to show all restaurants
            self.currentFilterOption = .none
            self.restaurantCollectionView.reloadData()
        })
        if currentFilterOption == .none {
            clearFilterAction.setValue(true, forKey: "checked")
        }
        alert.addAction(clearFilterAction)
        
        // Cancel option
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        // For iPad compatibility
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = (sender as! UIButton).frame
        }
        
        // Present the action sheet
        self.present(alert, animated: true, completion: nil)
    }

}

extension RestaurantViewController: RestaurantEditDelegate {
    func didAddNewRestaurant(_ restaurant: RestaurantEntity) {
        // Add the new restaurant to the data source
        self.restaurants.append(restaurant)
        // Reload the collection view to display the new restaurant
        self.restaurantCollectionView.reloadData()
    }
}
