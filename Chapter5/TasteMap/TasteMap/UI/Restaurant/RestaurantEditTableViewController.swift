//
//  RestaurantEditTableViewController.swift
//  TasteMap
//
//  Created by Kevin McNeish on 9/2/24.
//

import UIKit
import SwiftUI

protocol RestaurantEditDelegate: AnyObject {
    func didAddNewRestaurant(_ restaurant: RestaurantEntity)
}

class RestaurantEditTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {

    var restaurantEntity = RestaurantEntity()
    var isNewRestaurant: Bool = false
    weak var delegate: RestaurantEditDelegate?
    var activePickerIndexPath: IndexPath?
    
    let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    let daysOfWeek = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    @IBOutlet weak var imgRestaurant: UIImageView!
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var btnDone: UIButton!
    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var lblCuisine: UILabel!
    @IBOutlet weak var txtPhone: UITextField!
    @IBOutlet weak var txtNeighborhood: UITextField!
    @IBOutlet weak var txtStreet: UITextField!
    @IBOutlet weak var txtPostalCode: UITextField!
    @IBOutlet weak var txtCity: UITextField!
    @IBOutlet weak var lblCountry: UILabel!
    @IBOutlet weak var txtLatitude: UITextField!
    @IBOutlet weak var txtLongitude: UITextField!
    
    @IBOutlet weak var btnSundayOpen: UIButton!
    @IBOutlet weak var btnSundayClose: UIButton!
    @IBOutlet weak var btnMondayOpen: UIButton!
    @IBOutlet weak var btnMondayClose: UIButton!
    @IBOutlet weak var btnTuesdayOpen: UIButton!
    @IBOutlet weak var btnTuesdayClose: UIButton!
    @IBOutlet weak var btnWednesdayOpen: UIButton!
    @IBOutlet weak var btnWednesdayClose: UIButton!
    @IBOutlet weak var btnThursdayOpen: UIButton!
    @IBOutlet weak var btnThursdayClose: UIButton!
    @IBOutlet weak var btnFridayOpen: UIButton!
    @IBOutlet weak var btnFridayClose: UIButton!
    @IBOutlet weak var btnSaturdayOpen: UIButton!
    @IBOutlet weak var btnSaturdayClose: UIButton!
    @IBOutlet var swtDays: [UISwitch]!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    var lastSelectedButton: UIButton?  // Track the last selected button
    var pickerIsVisible = false
    var selectedButtonTag: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Disable the Done button initially
        btnDone.isEnabled = false

        // Add a target action to monitor text changes
        txtName.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        for switchControl in swtDays {
            switchControl.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        }
        
        if self.isNewRestaurant {
            ensureHoursArrayIsComplete()
        }
        else {
            self.title = restaurantEntity.name
            self.populateUIFromEntity()
        }
        setupButtons()
        
        // Add minus button to latitude/longitude text fields
        txtLatitude.keyboardType = .decimalPad
        txtLongitude.keyboardType = .decimalPad
        let accessoryView = createMinusAccessoryView()
        txtLatitude.inputAccessoryView = accessoryView
        txtLongitude.inputAccessoryView = accessoryView
    }
    
    func createMinusAccessoryView() -> UIView {
        let accessoryView = UIToolbar()
        accessoryView.sizeToFit()
        
        let minusButton = UIBarButtonItem(title: "-", style: .plain, target: self, action: #selector(addMinusSign))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        accessoryView.items = [flexibleSpace, minusButton, flexibleSpace]
        return accessoryView
    }

    @objc func addMinusSign() {
        if let currentText = txtLatitude.isFirstResponder ? txtLatitude.text : txtLongitude.text {
            let updatedText = currentText.hasPrefix("-") ? String(currentText.dropFirst()) : "-" + currentText
            if txtLatitude.isFirstResponder {
                txtLatitude.text = updatedText
            } else if txtLongitude.isFirstResponder {
                txtLongitude.text = updatedText
            }
        }
    }
    
    func populateUIFromEntity()
    {
        self.btnCancel.isHidden = true
        self.btnDone.isHidden = true
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneTapped))
        if let imageData = restaurantEntity.photo {
            let image = UIImage(data: imageData) // Convert Data to UIImage
            self.imgRestaurant.image = image // Display it in the UIImageView
        }
        self.btnDone.isEnabled = true
        self.txtName.text = self.restaurantEntity.name
        if let cuisine = self.restaurantEntity.cuisine?.name {
            self.lblCuisine.text = cuisine  // Only store the cuisine if one is set
        }
        self.txtPhone.text = self.restaurantEntity.phone
        self.txtNeighborhood.text = self.restaurantEntity.neighborhood
        self.txtStreet.text = self.restaurantEntity.address
        self.txtPostalCode.text = self.restaurantEntity.postalCode
        self.txtCity.text = self.restaurantEntity.city
        if let country = self.restaurantEntity.country {
            self.lblCountry.text = country
        }
        
        if let latitude = self.restaurantEntity.latitude {
            self.txtLatitude.text = "\(latitude)"
        }
        if let longitude = self.restaurantEntity.longitude {
            self.txtLongitude.text = "\(longitude)"
        }
        
        // Populate operating hours for each day
        for (index, switchControl) in swtDays.enumerated() {
            if let operatingHours = restaurantEntity.hours?.first(where: { $0.dayOfWeek == Int16(index + 1) }) {
                if let openTime = operatingHours.openTime {
                    let openTimeString = timeFormatter.string(from: openTime)
                    let openButton = [btnSundayOpen, btnMondayOpen, btnTuesdayOpen, btnWednesdayOpen, btnThursdayOpen, btnFridayOpen, btnSaturdayOpen][index]
                    openButton?.setTitle(openTimeString, for: .normal)
                }
                
                if let closeTime = operatingHours.closingTime {
                    let closeTimeString = timeFormatter.string(from: closeTime)
                    let closeButton = [btnSundayClose, btnMondayClose, btnTuesdayClose, btnWednesdayClose, btnThursdayClose, btnFridayClose, btnSaturdayClose][index]
                    closeButton?.setTitle(closeTimeString, for: .normal)
                }
                
                // Enable the switch for the day if either open or close time is set
                switchControl.isOn = operatingHours.openTime != nil || operatingHours.closingTime != nil
            } else {
                // Set the day as closed if no operating hours are available
                switchControl.isOn = false
                let openButton = [btnSundayOpen, btnMondayOpen, btnTuesdayOpen, btnWednesdayOpen, btnThursdayOpen, btnFridayOpen, btnSaturdayOpen][index]
                let closeButton = [btnSundayClose, btnMondayClose, btnTuesdayClose, btnWednesdayClose, btnThursdayClose, btnFridayClose, btnSaturdayClose][index]
                openButton?.setTitle("Closed", for: .normal)
                closeButton?.setTitle("Closed", for: .normal)
            }
        }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        // Enable Done button if name isn’t empty
        if let name = textField.text, !name.isEmpty {
            btnDone.isEnabled = true
        }
        else {
            btnDone.isEnabled = false
        }
    }
    
    @IBAction func getCurrentLocation(_ sender: Any) {
        self.txtStreet.text = Location.shared.locationEntity?.address
        self.txtCity.text = Location.shared.locationEntity?.city
        self.txtPostalCode.text = Location.shared.locationEntity?.postalCode
        self.lblCountry.text = Location.shared.locationEntity?.country
        self.restaurantEntity.country = Location.shared.locationEntity?.country
        if let latitude = Location.shared.locationEntity?.latitude {
            self.txtLatitude.text = String(format: "%.5f", latitude)
        }
        if let longitude = Location.shared.locationEntity?.longitude {
            self.txtLongitude.text = String(format: "%.5f", longitude)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Check if the segue is the MealsSegue
        if segue.identifier == "MealsSegue" {
            // Ensure the destination is the correct view controller
            if let mealsCollectionViewController = segue.destination as? MealCollectionViewController {
                // Pass the restaurant entity to the MealsViewController
                mealsCollectionViewController.restaurantEntity = self.restaurantEntity
            }
        }
    }
    
    @IBAction func timeButtonTapped(_ sender: UIButton) {
        // Dismiss the keyboard if it's open
        view.endEditing(true)
        
        // Step 1: Reset the color of the previous button
        lastSelectedButton?.tintColor = UIColor.label
        
        // Step 2: Check if the same button was tapped (and if so, hide the picker)
        if sender == lastSelectedButton {
            lastSelectedButton = nil  // Deselect the button
            pickerIsVisible = !pickerIsVisible
        } else {
            pickerIsVisible = true
            // Step 3: Update the newly selected button's color to accent color
            sender.tintColor = UIColor.accent
        }
        
        let selectedButtonTag = sender.tag
        let isOpenTime = selectedButtonTag % 2 != 0  // Odd tags are for open time, even for close time
        let selectedDayIndex = (selectedButtonTag - 1) / 2  // Day index, from 0 (Sunday) to 6 (Saturday)

        // Step 4: Fetch the previously stored open and close times separately
        var previousOpenTime: Date? = nil
        var previousCloseTime: Date? = nil

        // Fetch the time for the currently selected day (open or close)
        if let operatingHours = restaurantEntity.hours?.first(where: { $0.dayOfWeek == Int16(selectedDayIndex + 1) }) {
            if isOpenTime, let openTime = operatingHours.openTime {
                // Set picker to the open time if available
                datePicker.setDate(openTime, animated: true)
                previousOpenTime = openTime
            } else if !isOpenTime, let closeTime = operatingHours.closingTime {
                // Set picker to the close time if available
                datePicker.setDate(closeTime, animated: true)
                previousCloseTime = closeTime
            } else {
                // No time set for this button yet, fetch the last selected times for either open or close
                if let lastSelectedButtonTag = lastSelectedButton?.tag, lastSelectedButtonTag != sender.tag {
                    let lastDayIndex = (lastSelectedButtonTag - 1) / 2  // Day index for last selected button
                    if let lastOperatingHours = restaurantEntity.hours?.first(where: { $0.dayOfWeek == Int16(lastDayIndex + 1) }) {
                        previousOpenTime = lastOperatingHours.openTime
                        previousCloseTime = lastOperatingHours.closingTime
                    }
                }
                
                // Assign the previous open or close time based on the current button tapped
                if isOpenTime, let previousOpenTime = previousOpenTime {
                    // Set the date picker and button title to the previous open time
                    datePicker.setDate(previousOpenTime, animated: true)
                    sender.setTitle(timeFormatter.string(from: previousOpenTime), for: .normal)
                    
                    // Update the open time in the restaurantEntity for this day
                    if let operatingHours = restaurantEntity.hours?.first(where: { $0.dayOfWeek == Int16(selectedDayIndex + 1) }) {
                        operatingHours.openTime = previousOpenTime
                    }
                } else if !isOpenTime, let previousCloseTime = previousCloseTime {
                    // Set the date picker and button title to the previous close time
                    datePicker.setDate(previousCloseTime, animated: true)
                    sender.setTitle(timeFormatter.string(from: previousCloseTime), for: .normal)
                    
                    // Update the close time in the restaurantEntity for this day
                    if let operatingHours = restaurantEntity.hours?.first(where: { $0.dayOfWeek == Int16(selectedDayIndex + 1) }) {
                        operatingHours.closingTime = previousCloseTime
                    }
                } else {
                    // No previous time, leave the date picker unchanged
                    print("No previous time to set.")
                }
            }
        }

        lastSelectedButton = sender  // Update the reference to the new button
        
        tableView.beginUpdates()
        tableView.endUpdates()
        self.scrollToBottom()
    }

    
    @IBAction func switchToggled(_ sender: UISwitch) {
        // Determine which switch was toggled using its index in the collection
        guard let switchIndex = swtDays.firstIndex(of: sender) else { return }
        
        // Find the corresponding "Open" and "Close" buttons
        let openButton: UIButton
        let closeButton: UIButton
        
        switch switchIndex {
        case 0:
            openButton = btnSundayOpen
            closeButton = btnSundayClose
        case 1:
            openButton = btnMondayOpen
            closeButton = btnMondayClose
        case 2:
            openButton = btnTuesdayOpen
            closeButton = btnTuesdayClose
        case 3:
            openButton = btnWednesdayOpen
            closeButton = btnWednesdayClose
        case 4:
            openButton = btnThursdayOpen
            closeButton = btnThursdayClose
        case 5:
            openButton = btnFridayOpen
            closeButton = btnFridayClose
        case 6:
            openButton = btnSaturdayOpen
            closeButton = btnSaturdayClose
        default:
            return
        }
        
        // Check the state of the switch
        if sender.isOn {
            // Enable the buttons and restore their time text (if applicable)
            openButton.isEnabled = true
            closeButton.isEnabled = true
            
            setupButtonTitle(openButton, closeButton: closeButton, forDay: switchIndex)
        } else {
            // Disable the buttons and set their titles to "Closed"
            openButton.isEnabled = false
            closeButton.isEnabled = false
            openButton.setTitle("Closed", for: .normal)
            closeButton.setTitle("Closed", for: .normal)
        }
    }
    
    func scrollToBottom() {
        let lastSectionIndex = tableView.numberOfSections - 1
        if lastSectionIndex >= 0 {
            let lastRowIndex = tableView.numberOfRows(inSection: lastSectionIndex) - 1
            if lastRowIndex >= 0 {
                let lastIndexPath = IndexPath(row: lastRowIndex, section: lastSectionIndex)
                tableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: true)
            }
        }
    }
    
    // Ensure all days of the week have an entry in hours
    func ensureHoursArrayIsComplete() {
        if restaurantEntity.hours == nil {
            restaurantEntity.hours = []
        }

        for dayIndex in 1...7 {
            if restaurantEntity.hours?.first(where: { $0.dayOfWeek == Int16(dayIndex) }) == nil {
                let newHours = OperatingHoursEntity(dayOfWeek: Int16(dayIndex), openTime: nil, closingTime: nil)
                restaurantEntity.hours?.append(newHours)
            }
        }
        restaurantEntity.hours?.sort(by: { $0.dayOfWeek ?? 0 < $1.dayOfWeek ?? 0 })  // Sort by day of week
    }
    
    func setupButtons() {
        setupButtonTitle(btnSundayOpen, closeButton: btnSundayClose, forDay: 0)
        setupButtonTitle(btnMondayOpen, closeButton: btnMondayClose, forDay: 1)
        setupButtonTitle(btnTuesdayOpen, closeButton: btnTuesdayClose, forDay: 2)
        setupButtonTitle(btnWednesdayOpen, closeButton: btnWednesdayClose, forDay: 3)
        setupButtonTitle(btnThursdayOpen, closeButton: btnThursdayClose, forDay: 4)
        setupButtonTitle(btnFridayOpen, closeButton: btnFridayClose, forDay: 5)
        setupButtonTitle(btnSaturdayOpen, closeButton: btnSaturdayClose, forDay: 6)
    }
    
    func setupButtonTitle(_ openButton: UIButton, closeButton: UIButton, forDay dayIndex: Int) {
        // Fetch the stored operating hours for the specific day
        if let operatingHours = restaurantEntity.hours?.first(where: { $0.dayOfWeek == Int16(dayIndex + 1) }) {
            
            // Only set the title if there's an open time
            if let openTime = operatingHours.openTime {
                let openTimeTitle = timeFormatter.string(from: openTime)
                openButton.setTitle(openTimeTitle, for: .normal)
            }
            
            // Only set the title if there's a close time
            if let closeTime = operatingHours.closingTime {
                let closeTimeTitle = timeFormatter.string(from: closeTime)
                closeButton.setTitle(closeTimeTitle, for: .normal)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Assuming the DatePicker is in row 7 (after the Saturday row) in section 1
        if indexPath.section == 1 && indexPath.row == 7 {
            return pickerIsVisible ? 216 : 0  // Toggle between showing and hiding the picker
        }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && indexPath.row == 2 {
            // Present the CuisineSelectionView
            let cuisineSelectionView = CuisineSelectionView(
                cuisines: Cuisine.shared.getAllCuisines(),
                currentCuisine: restaurantEntity.cuisine,
                onCuisineSelected: { selectedCuisine in
                    self.lblCuisine.text = selectedCuisine.name
                    self.restaurantEntity.cuisine = selectedCuisine
                }
            )

            let hostingController = UIHostingController(rootView: cuisineSelectionView)
            present(hostingController, animated: true, completion: nil)

            // Deselect the row with animation after a slight delay
            tableView.deselectRow(at: indexPath, animated: true)
        }
        else if indexPath.section == 0 && indexPath.row == 7 {
            // Find the current selected country based on the stored country name or fallback to the first country
            let currentCountry: Locale.Region?

            if let countryName = restaurantEntity.country, !countryName.isEmpty {
                // If restaurantEntity.country is set, find the matching Locale.Region
                currentCountry = Locale.Region.isoRegions.first {
                    let localizedCountryName = Locale.current.localizedString(forRegionCode: $0.identifier)
                    return localizedCountryName == countryName
                }
            } else {
                // If restaurantEntity.country is not set, fallback to the first region
                currentCountry = Locale.Region.isoRegions.first
            }

            let countrySelectionView = CountrySelectionView(
                currentCountry: currentCountry, // Pass the Locale.Region of the current country
                onCountrySelected: { selectedCountryName in
                    // Update the label and entity with the selected country's name
                    self.lblCountry.text = selectedCountryName
                    self.restaurantEntity.country = selectedCountryName
                }
            )

            let hostingController = UIHostingController(rootView: countrySelectionView)
            present(hostingController, animated: true, completion: nil)

            // Deselect the row with animation after a slight delay
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    @IBAction func timePickerValueChanged(_ sender: UIDatePicker) {

        // Ensure the last selected button is valid
        guard let selectedButtonTag = lastSelectedButton?.tag else { return }

        // Format the selected time as a string
        let formattedTime = timeFormatter.string(from: sender.date)

        // Update the title of the last selected button with the new formatted time
        lastSelectedButton?.setTitle(formattedTime, for: .normal)

        // Determine if the button is for open or close based on the tag number
        let isOpenTime = selectedButtonTag % 2 != 0  // Odd tags are for open time, even tags for close time
        let selectedDayIndex = (selectedButtonTag - 1) / 2  // Day index, from 0 (Sunday) to 6 (Saturday)

        // Update the corresponding OperatingHoursEntity in the restaurantEntity.hours array
        if let operatingHours = restaurantEntity.hours?.first(where: { $0.dayOfWeek == Int16(selectedDayIndex + 1) }) {
            if isOpenTime {
                operatingHours.openTime = sender.date  // Update open time
            } else {
                operatingHours.closingTime = sender.date  // Update close time
            }
        }
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func doneTapped(_ sender: UIButton) {
        
        // Update the restaurant entity with the provided name and other details
        restaurantEntity.name = self.txtName.text!
        restaurantEntity.dateTimeCreated = Date() // Set the current date/time for when the restaurant was created
        restaurantEntity.phone = self.txtPhone.text
        restaurantEntity.neighborhood = self.txtNeighborhood.text
        restaurantEntity.address = self.txtStreet.text
        restaurantEntity.city = self.txtCity.text
        restaurantEntity.postalCode = self.txtPostalCode.text
        
        if let latitudeText = self.txtLatitude.text, let latitudeValue = Double(latitudeText) {
            // Successfully converted the text to a Double
            self.restaurantEntity.latitude = latitudeValue
        }
        if let longitudeText = self.txtLongitude.text, let longitudeValue = Double(longitudeText) {
            // Successfully converted the text to a Double
            self.restaurantEntity.longitude = longitudeValue
        }
                
        // Update the operating hours for each day based on the switches and buttons
        for (index, switchControl) in swtDays.enumerated() {
            let isSwitchOn = switchControl.isOn
            if let operatingHours = restaurantEntity.hours?.first(where: { $0.dayOfWeek == Int16(index + 1) }) {
                if isSwitchOn {
                    // Fetch the open and close times from the buttons (if set)
                    let openButton = [btnSundayOpen, btnMondayOpen, btnTuesdayOpen, btnWednesdayOpen, btnThursdayOpen, btnFridayOpen, btnSaturdayOpen][index]
                    let closeButton = [btnSundayClose, btnMondayClose, btnTuesdayClose, btnWednesdayClose, btnThursdayClose, btnFridayClose, btnSaturdayClose][index]
                    
                    if let openTime = openButton?.title(for: .normal), openTime != "Closed" {
                        operatingHours.openTime = timeFormatter.date(from: openTime)
                    }
                    
                    if let closeTime = closeButton?.title(for: .normal), closeTime != "Closed" {
                        operatingHours.closingTime = timeFormatter.date(from: closeTime)
                    }
                } else {
                    // Mark the day as closed if the switch is off
                    operatingHours.openTime = nil
                    operatingHours.closingTime = nil
                }
            }
        }
        
        // Save the restaurant and its operating hours
        let result = Restaurant<RestaurantEntity>().insertEntity(restaurantEntity)
        if result.state == .saveComplete {
            // Dismiss the view if the save is successful
            // Notify the delegate about the new restaurant
            delegate?.didAddNewRestaurant(restaurantEntity)
            
            // Dismiss or pop the view controller depending on how it was presented
            if self.presentingViewController != nil {
                // If presented modally, dismiss it
                self.dismiss(animated: true, completion: nil)
            }
            else if let navigationController = self.navigationController {
                // If pushed via a navigation controller, pop it
                navigationController.popViewController(animated: true)
            }
        }
        else {
            // Handle save errors (you can show an alert or print a message)
            let alert = UIAlertController(title: "Save Error", message: "Failed to save the restaurant. Please try again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func addPhoto(_ sender: Any) {
        let alertController = UIAlertController(title: "Add Photo", message: "Choose a photo source", preferredStyle: .actionSheet)
                
        // Check if the camera is available
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAlertAction(title: "Camera", style: .default) { _ in
                self.presentImagePicker(sourceType: .camera)
            }
            alertController.addAction(cameraAction)
        }
        
        // Option to select from the photo library
        let libraryAction = UIAlertAction(title: "Photo Library", style: .default) { _ in
            self.presentImagePicker(sourceType: .photoLibrary)
        }
        alertController.addAction(libraryAction)
        
        // Cancel action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = sourceType
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
        
    // MARK: - UIImagePickerControllerDelegate Methods
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[.editedImage] as? UIImage {
            imgRestaurant.image = editedImage
            self.restaurantEntity.photo = editedImage.jpegData(compressionQuality: 0.8)
        } else if let originalImage = info[.originalImage] as? UIImage {
            imgRestaurant.image = originalImage
            self.restaurantEntity.photo = originalImage.jpegData(compressionQuality: 0.8)
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }

}
