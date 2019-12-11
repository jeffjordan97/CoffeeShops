//
//  ViewController.swift
//  Coursework2
//
//  Created by Jordan, Jeffrey on 27/11/2019.
//  Copyright © 2019 Jordan, Jeffrey. All rights reserved.
//

import UIKit
import MapKit
import CoreData

struct coffeeShop: Decodable {
    var id: String
    var name: String
    var latitude: String
    var longitude: String
}
struct coffeeOnCampus: Decodable {
    var data: [coffeeShop]
    var code: Int
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate, CLLocationManagerDelegate, UISearchBarDelegate {
    
    var locationManager = CLLocationManager() //create an instance to manage our the user’s location.
    
    @IBOutlet weak var table: UITableView!
    
    @IBOutlet weak var map: MKMapView!
    
    var coffeeShops: coffeeOnCampus?
    
    var passShop: coffeeShop?
    
    var searchCoffeeShops = [coffeeShop]()
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    var isSearching = false

    
    func retrieveJSON(){
        
        if let url = URL(string:  "https://dentistry.liverpool.ac.uk/_ajax/coffee/") {
            let session = URLSession.shared
            
            session.dataTask(with: url) { (data, response, err) in
                
                guard let jsonData = data else {
                    return }
                
                do{
                    let decoder = JSONDecoder()
                    var shops = try decoder.decode(coffeeOnCampus.self, from: jsonData)
                    var annotation = MKPointAnnotation()
                    var coordinates = CLLocationCoordinate2D()
                    
                    for aShop in shops.data {
                                               
                        //add function for addAnnotation?
                        //sets annotations for each of the shops on the mapView
                        annotation = MKPointAnnotation()
                        coordinates = CLLocationCoordinate2D(latitude: Double(aShop.latitude)!, longitude: Double(aShop.longitude)!)
                        annotation.coordinate = coordinates
                        annotation.title = aShop.name
                        self.map.addAnnotation(annotation)
                        //print("annotation added - \(aShop.name)")
                    }
                    //print(shops.code)
                    self.coffeeShops = shops
                    
                    //print("count - \(coffeeShops?.data.count)")
                    DispatchQueue.main.async {
                        //self.handleCoffeeShops(allShops: self.coffeeShops!)
                        self.table.reloadData()
                    }
                    
                } catch let jsonErr {
                    print("Error decoding JSON", jsonErr)
                }
            }.resume()
        }
    }
    
    
    func handleCoffeeShops(allShops: coffeeOnCampus){
        
        coffeeShops?.data = allShops.data.sorted(by: { locationManager.location!.distance(from: CLLocation(latitude: Double($0.latitude)!, longitude: Double($0.longitude)!)) < locationManager.location!.distance(from: CLLocation(latitude: Double($1.latitude)!, longitude: Double($1.longitude)!)) })
        
        self.table.reloadData()
    }
    

    //returns number of rows for the table
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if isSearching {
            return searchCoffeeShops.count
        }
        else{
            return coffeeShops?.data.count ?? 0
        }
        
    }
    
    //returns each cell for each row of the  table
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "myCell")
        if coffeeShops?.data.count != nil {
            cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
            
            //limits the distance to 2 decimal places
            if locationManager.location != nil {
                if isSearching {
                    let shop = searchCoffeeShops[indexPath.row]
                    
                    let latitude = Double(shop.latitude)
                    let longitude = Double(shop.longitude)
                    let distance = String(format: "%.2f", locationManager.location!.distance(from: CLLocation(latitude: latitude!, longitude: longitude!)))
                    
                    cell.textLabel?.text = ("\(shop.name) (\(distance)m)")
                    
                } else {
                    let shop = coffeeShops?.data[indexPath.row]
                    
                    let latitude = Double(shop!.latitude)!
                    let longitude = Double(shop!.longitude)!
                    let distance = String(format: "%.2f", locationManager.location!.distance(from: CLLocation(latitude: latitude, longitude: longitude)))
                    
                    cell.textLabel?.text = ("\(shop!.name) (\(distance)m)")
                }
                
            }
            
        }
        return cell
    }
    
    
    //need to arrange to invoke a segue when we select cells in our table and so we add another method to this View Controller
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isSearching {
            passShop = searchCoffeeShops[indexPath.row]
        } else {
            passShop = coffeeShops?.data[indexPath.row]
        }
        
        performSegue(withIdentifier: "toDetails", sender: nil)
    }
    
    
    //function to handle location of user and call handleCoffeeShops
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locationOfUser = locations[0] //get the first location (ignore any others)
        let latitude = locationOfUser.coordinate.latitude
        let longitude = locationOfUser.coordinate.longitude
        let latDelta: CLLocationDegrees = 0.002
        let lonDelta: CLLocationDegrees = 0.002
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = MKCoordinateRegion(center: location, span: span)
        self.map.setRegion(region, animated: true)
        
        self.handleCoffeeShops(allShops: coffeeShops!)
    }
    
    
    //function to determine which annotation has been clicked
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let selectedView = view.annotation!
        
        //determines shop clicked based on the annotation location (latitute & longitude)
        passShop = coffeeShops?.data.first(where: {(Double($0.latitude)! == selectedView.coordinate.latitude) && (Double($0.longitude)! == selectedView.coordinate.longitude)})
        
        performSegue(withIdentifier: "toDetails", sender: nil)
    }
    
    
    //search bar function to add coffee shops to the filtered coffee shops array, based on the search text entered
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text == nil || searchBar.text == "" {
            isSearching = false
            view.endEditing(true)
            self.table.reloadData()
        } else {
            isSearching = true
            searchCoffeeShops = (coffeeShops?.data.filter({$0.name.contains(searchText)}))!
            
            self.table.reloadData()
            
            
        }
    }
    
    
    //hide search bar keyboard on click of search button
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    //Dismisses keyboard
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    
    //hide search bar keyboard when user clicks
    func hideKeyboardWhenTapped() {
        let click: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.dismissKeyboard))
        click.cancelsTouchesInView = false
        view.addGestureRecognizer(click)
    }
    
    
    //function to pass info to detailed view controller
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "toDetails"){
            let detailedVC = segue.destination as! DetailedViewController
            detailedVC.selectedShop = passShop
        }
    }
    
    
    @IBAction func unwindToRootViewController(segue: UIStoryboardSegue) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        retrieveJSON()
        //var userLocation = locationManager.location
        locationManager.delegate = self as CLLocationManagerDelegate //we want messages about location
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.requestWhenInUseAuthorization() //ask the user for permission to get their location
        locationManager.startUpdatingLocation() //and start receiving those messages (if we’re allowed to)
        
        searchBar.delegate = self
        searchBar.returnKeyType = UIReturnKeyType.done
        hideKeyboardWhenTapped()
    }
    
    
}
