//
//  MealCollectionViewController.swift
//  TasteMap
//
//  Created by Kevin McNeish on 9/10/24.
//

import UIKit

private let reuseIdentifier = "MealCell"

class MealCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var restaurantEntity: RestaurantEntity?
    var meals = [MealEntity]()
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    // Placeholder view for when there are no meals
    let noMealsLabel: UILabel = {
        let label = UILabel()
        label.text = "No meals available"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Do any additional setup after loading the view.
        self.title = restaurantEntity?.name
        
//        // TEMP: Create a test meal entity
//        let testMeal = MealEntity(
//            dateTime: Date(),
//            id: UUID(),
//            name: "Turkey club",
//            photo: UIImage(named: "TurkeyClub")?.jpegData(compressionQuality: 1.0),
//            comment: "Delicious ingredients, real turkey and crispy bread!",
//            restaurant: restaurantEntity!
//        )
//        
//        // Add the test meal to the meals array
//        meals.append(testMeal)
        
        // Setup the placeholder label
        self.view.addSubview(noMealsLabel)
        NSLayoutConstraint.activate([
            noMealsLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            noMealsLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])
        
        self.loadMealsForRestaurant()
    }
    
    func loadMealsForRestaurant() {
        guard let restaurant = restaurantEntity else {
            print("Error: No restaurant entity found.")
            return
        }
        
        // Fetch meals associated with the restaurant using the business object
        meals = Meal.shared.getMeals(for: restaurant)
        
        // Reload the collection view to display the fetched meals
        collectionView.reloadData()
        
        // Show/hide the placeholder view
        noMealsLabel.isHidden = !meals.isEmpty
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Check if the segue identifier matches the AddMealSegue
        if segue.identifier == "AddMealSegue" {
            // Get the destination view controller
            if let mealEditVC = segue.destination as? MealEditTableViewController {
                // Pass the restaurant entity to the MealEditTableViewController
                mealEditVC.restaurantEntity = self.restaurantEntity
                mealEditVC.delegate = self
            }
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return meals.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? MealCell else {
            return UICollectionViewCell()
        }
                
        let meal = meals[indexPath.item]
        
        // Set the meal name
        cell.lblMealName.text = meal.name
        
        // Use the pre-configured dateFormatter
        cell.lblDate.text = dateFormatter.string(from: meal.dateTime)
        
        // Set the meal image if available
        if let mealPhoto = meal.photo {
            cell.imgMeal.image = UIImage(data: mealPhoto)
        }
        else {
            cell.imgMeal.image = UIImage(named: "DefaultMeal")
        }
        
        // Set the description or comments
        cell.lblComments.text = meal.comment ?? "No description available"
        
        return cell
    }

    // UICollectionViewDelegateFlowLayout method
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Full width of the collection view
        let width = collectionView.bounds.width
        let height: CGFloat = 180.0 // Fixed height
        
        return CGSize(width: width, height: height)
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}

extension MealCollectionViewController: MealEditDelegate {
    func didAddNewMeal(_ meal: MealEntity) {
        // Add the new meal to the data source
        self.meals.append(meal)
        // Reload the collection view to display the new restaurant
        self.collectionView.reloadData()
        // Hide the placeholder view
        noMealsLabel.isHidden = !meals.isEmpty
    }
}
