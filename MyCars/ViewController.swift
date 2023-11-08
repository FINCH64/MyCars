//
//  ViewController.swift
//  MyCars
//
//  Created by f1nch on 01.11.2023

import UIKit
import CoreData

class ViewController: UIViewController {
    
    var context: NSManagedObjectContext!
    let userDefaults = UserDefaults.standard
    var car: Car!
    
    @IBOutlet weak var segmentedControl: UISegmentedControl! {
        didSet {
            UpdateSegmentedControl()
            segmentedControl.selectedSegmentTintColor = .white
            
            let whiteTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
            let blackTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
            
            UISegmentedControl.appearance().setTitleTextAttributes(whiteTitleTextAttributes, for: .normal)
            UISegmentedControl.appearance().setTitleTextAttributes(blackTitleTextAttributes, for: .selected)
        }
    }
    @IBOutlet weak var markLabel: UILabel!
    @IBOutlet weak var modelLabel: UILabel!
    @IBOutlet weak var carImageView: UIImageView!
    @IBOutlet weak var lastTimeStartedLabel: UILabel!
    @IBOutlet weak var numberOfTripsLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var myChoiceImageView: UIImageView!
    
    @IBAction func segmentedCtrlPressed(_ sender: UISegmentedControl) {
        UpdateSegmentedControl()
    }
    
    @IBAction func startEnginePressed(_ sender: UIButton) {
        car.timesDriven += 1
        car.lastStarted = Date()
        
        do {
            try context.save()
            insertDataFromSelectedCar(car: car)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    @IBAction func rateItPressed(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Rate it", message: "Rate thei car", preferredStyle: .alert)
        let rateAction = UIAlertAction(title: "Rate", style: .default) { action in
            if let text = alertController.textFields?.first?.text {
                self.UpdateRating(rating: (text as NSString).doubleValue)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default)
        
        alertController.addTextField { textField in
            textField.keyboardType = .numberPad
        }
        
        alertController.addAction(rateAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
    
    private func UpdateSegmentedControl() {
        let fetchRequest: NSFetchRequest<Car> = Car.fetchRequest()
        let mark = segmentedControl.titleForSegment(at: segmentedControl.selectedSegmentIndex)
        fetchRequest.predicate = NSPredicate(format: "mark = %@", mark!)
        
        do {
            let results = try context.fetch(fetchRequest)
            car = results.first
            insertDataFromSelectedCar(car: car)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    private func UpdateRating(rating: Double) {
        car.rating = rating
        
        do {
            try context.save()
            insertDataFromSelectedCar(car: car)
        } catch let error as NSError {
            let alertController = UIAlertController(title: "Wrong input", message: "Wrong rating value", preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "OK", style: .default)
            
            alertController.addAction(okAction)
            present(alertController, animated: true)
            print(error.localizedDescription)
        }
    }
    
    private func insertDataFromSelectedCar(car: Car) {
        lazy var dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        
        carImageView.image = UIImage(data: car.imageData!)
        markLabel.text = car.mark
        modelLabel.text = car.model
        
        myChoiceImageView.isHidden = !(car.myChoice)
        ratingLabel.text = "Car rating: \(car.rating) / 10"
        numberOfTripsLabel.text = "Number of trips: \(car.timesDriven)"
        
        lastTimeStartedLabel.text = "Last time started: \(dateFormatter.string(from: car.lastStarted!))"
        
        segmentedControl.backgroundColor = car.tintColor as? UIColor
    }
    
    private func getColor(colorDictionary: [String:Float]) -> UIColor {
        guard let red = colorDictionary["red"],
              let blue = colorDictionary["blue"],
              let green = colorDictionary["green"] else {return UIColor()}
        
        return UIColor(red: CGFloat(red/255), green: CGFloat(green/255), blue: CGFloat(blue/255), alpha: CGFloat(1.0))
    }
    
    private func getDataFromFile() {
        guard let pathToFile = Bundle.main.path(forResource: "data", ofType: "plist"),
              let dataArray = NSArray(contentsOfFile: pathToFile) else {return}
        
        for dictionary in dataArray {
            let entity = NSEntityDescription.entity(forEntityName: "Car", in: context)
            let car = NSManagedObject(entity: entity!, insertInto: context) as! Car
            
            let carDictionary = dictionary as! [String:AnyObject]
            car.mark = carDictionary["mark"] as? String
            car.model = carDictionary["model"] as? String
            car.rating = carDictionary["rating"] as! Double
            car.lastStarted = carDictionary["lastStarted"] as? Date
            car.timesDriven = carDictionary["timesDriven"] as! Int16
            car.myChoice = carDictionary["myChoice"] as! Bool
            
            let imageName = carDictionary["imageName"] as! String
            let image = UIImage(named: imageName)
            let imageData = image?.pngData()
            
            car.imageData = imageData
            
            if let colorDictionary = carDictionary["tintColor"] as? [String:Float] {
                car.tintColor = getColor(colorDictionary: colorDictionary)
            }
            
            do {
                try context.save()
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        }
        
        
        
        userDefaults.setValue(true, forKey: "isDataReadedFromFile")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if userDefaults.bool(forKey: "isDataReadedFromFile") == true {
            getDataFromFile()
        }
    }
    
}

