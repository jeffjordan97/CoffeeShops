//
//  DetailedViewController.swift
//  Coursework2
//
//  Created by Jordan, Jeffrey on 27/11/2019.
//  Copyright © 2019 Jordan, Jeffrey. All rights reserved.
//

import UIKit
import MapKit

class DetailedViewController: UIViewController {
    
    struct coffeeShopDetails: Decodable {
        var url: String?
        var photo_url: URL?
        var phone_number: String?
        var opening_hours: [String:String]?
    }
    
    struct coffeeShopData: Decodable {
        var data: coffeeShopDetails
        var code: Int
    }
    
    var shopDetails: coffeeShopDetails?
    
    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var addressLabel: UILabel!
    
    @IBOutlet weak var urlTextView: UITextView!
    
    @IBOutlet weak var phoneNumberLabel: UILabel!
    
    @IBOutlet weak var openingTimesLabel: UILabel!
    
    @IBOutlet weak var photo: UIImageView!
    
    var selectedShop: coffeeShop?
    
    //var selectedShopDetails: coffeeOnCampus?
    
    //sets the title of the selected shop
    func setTitle(){
        label.text = selectedShop!.name
    }
    
    
    //MARK: RetrieveJSONDetailed
    //retrieves JSON data for the selected shop
    func retrieveJSONForID(){
        //stores id for selected shop
        let id = String(selectedShop!.id)
        //converts urlString to a string containing the id of the selected shop
        let urlString = "https://dentistry.liverpool.ac.uk/_ajax/coffee/info/?id=\(id)"
        
        guard let theUrl = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: theUrl) { (data, response
            , error) in
            guard let data = data else { return }
            do {
                let decoder = JSONDecoder()
                let shop = try decoder.decode(coffeeShopData.self, from: data)
                self.shopDetails = shop.data
                DispatchQueue.main.async {
                    self.setLabels(shopDetails: self.shopDetails)
                }
            } catch let err {
                print("Err - ", err)
            }
        }.resume()
    }
    
    
    //set labels/text views displayed on detailed view controller
    func setLabels(shopDetails: coffeeShopDetails?){
        if shopDetails != nil {
            setUrl(shopURL: shopDetails!.url)
            setPhoneNumber(shopPhoneNumber: shopDetails!.phone_number)
            setOpeningHours(shopOpeningHours: shopDetails!.opening_hours)
            setPhoto(photoURL: shopDetails!.photo_url)
        }
        else {
            print("shopDetails Empty :(")
        }
        
    }
    
    
    //set URL of selected shop to label
    func setUrl(shopURL: String?){
        if shopURL != nil {
            urlTextView.layer.borderColor = UIColor.black.cgColor
            urlTextView.layer.masksToBounds = true
            urlTextView.layer.borderWidth = 1.0
            urlTextView.layer.cornerRadius = 10.0
            urlTextView.text = String(shopURL!)
        }
        else {
            urlTextView.text = "Unavailable"
        }
        
    }
    
    
    //sets phone number label and manages case if nil or empty ("")
    func setPhoneNumber(shopPhoneNumber: String?) {
        //if not nil print the phone number
        if shopDetails?.phone_number != nil {
            phoneNumberLabel.text = shopPhoneNumber!
            
            //if the phone number is empty (""), print unavailable
            if (shopDetails?.phone_number)! == "" {
                phoneNumberLabel.text = "Unavailable"
            }
        }
        else{
            phoneNumberLabel.text = "Unavailable"
        }
        
        phoneNumberLabel.layer.borderColor = UIColor.black.cgColor
        phoneNumberLabel.layer.masksToBounds = true
        phoneNumberLabel.layer.borderWidth = 1.0
        phoneNumberLabel.layer.cornerRadius = 10.0
    }
    
    
    //sets opening hours label and manages case if nil
    func setOpeningHours(shopOpeningHours: [String:String]?){
        
        if shopOpeningHours?.count != nil {
            
            //checks whether there are hours for the day
            let string = "\nMonday : \(checkHours(openingHours: shopOpeningHours, day: "monday"))"+"\n Tuesday : \(checkHours(openingHours: shopOpeningHours, day: "tuesday"))"+"\n Wednesday : \(checkHours(openingHours: shopOpeningHours, day: "wednesday"))"+"\n Thursday : \(checkHours(openingHours: shopOpeningHours, day: "thursday"))"+"\n Friday : \(checkHours(openingHours: shopOpeningHours, day: "friday"))"
            
            openingTimesLabel.text = string
            openingTimesLabel.layer.borderColor = UIColor.black.cgColor
            openingTimesLabel.layer.masksToBounds = true
            openingTimesLabel.layer.borderWidth = 1.0
            openingTimesLabel.layer.cornerRadius = 20.0
        }
        else{
            openingTimesLabel.text = "\nunavailable"
        }
    }
    
    //prints closed for the opening hours value given the day, if the hours is nil
    func checkHours(openingHours: [String:String]?, day: String) -> String {
        var hoursOutput: String
        if openingHours![day] != nil {
            //print("Day - ",day)
            hoursOutput = openingHours![day]!
        }
        else{
            print("Error (day) - ",day)
            hoursOutput = "closed"
        }
        return hoursOutput
    }
    
    
    //func to handle photo, if not nil
    func setPhoto(photoURL: URL?){
        if photoURL != nil {
            let imageData = try! Data(contentsOf: photoURL!)
            let image = UIImage(data: imageData)
            photo.image = image!
        }
    }
    
    func printAddress(_ address: String) {
        addressLabel.text = address
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        setTitle()
        
        //check if JSON already received for ID?
        retrieveJSONForID()
        
        //get location of shop clicked
        let location = CLLocation(latitude: Double((selectedShop?.latitude)!)!, longitude: Double((selectedShop?.longitude)!)!)
        
        //string used to store the address of the coffee shop clicked
        var address = ""
        
        //converts shop location coordinates to readable address
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: { (placemarks, error) in
            if error != nil {
                print(error!)
            } else {
                if let placemark = placemarks?[0] {
                    if placemark.subThoroughfare != nil {
                        address = placemark.subThoroughfare!+" "
                    }
                    if placemark.thoroughfare != nil {
                        address += placemark.thoroughfare!
                    }
                    if placemark.locality != nil {
                        address += "\n"+placemark.locality!
                    }
                    if placemark.administrativeArea != nil {
                        address += "\n"+placemark.administrativeArea!
                    }
                    if placemark.postalCode != nil {
                        address += "\n"+placemark.postalCode!
                    }
                }
            }
            //print(address)
            self.printAddress(address)
        } )
        
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
