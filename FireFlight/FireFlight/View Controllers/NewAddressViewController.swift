//
//  NewAddressViewController.swift
//  FireFlight
//
//  Created by Kobe McKee on 8/26/19.
//  Copyright © 2019 Lambda. All rights reserved.
//

import UIKit
import CoreLocation
import Lottie

class NewAddressViewController: UIViewController, UITextFieldDelegate {
    
    var savedAddress: UserAddress?
    
    var apiController: APIController?
    var addressLabel: String?
    var addressString: String?
    var newLocation: CLLocation? {
        didSet {
            //print(newLocation)
            saveAddress() 
        }
    }
    
    @IBOutlet weak var sliderValueLabel: UILabel!
    @IBOutlet weak var radiusSlider: UISlider!
    @IBOutlet weak var labelTextField: UITextField!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var streetTextField: UITextField!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var stateTextField: UITextField!
    @IBOutlet weak var zipCodeTextField: UITextField!
    
    @IBOutlet weak var animationView: AnimationView!
    @IBOutlet weak var addAddressButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        animationView.isHidden = true
        stylize()
        
        if savedAddress != nil { importAddress() }
        
        zipCodeTextField.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    func stylize() {
        
        let closeImage = UIImage(named: "closeButton")
        let tintedImage = closeImage?.withRenderingMode(.alwaysTemplate)
        closeButton.setImage(tintedImage, for: .normal)
        closeButton.tintColor = AppearanceHelper.ming

        labelTextField.backgroundColor = AppearanceHelper.ming
        labelTextField.textColor = .white
        labelTextField.attributedPlaceholder = NSAttributedString(string: "Label", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightText])
        
        streetTextField.backgroundColor = AppearanceHelper.ming
        streetTextField.textColor = .white
        streetTextField.attributedPlaceholder = NSAttributedString(string: "Street", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightText])
        
        cityTextField.backgroundColor = AppearanceHelper.ming
        cityTextField.textColor = .white
        cityTextField.attributedPlaceholder = NSAttributedString(string: "City", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightText])
        
        stateTextField.backgroundColor = AppearanceHelper.ming
        stateTextField.textColor = .white
        stateTextField.attributedPlaceholder = NSAttributedString(string: "State (Ex: CA)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightText])
        
        zipCodeTextField.backgroundColor = AppearanceHelper.ming
        zipCodeTextField.textColor = .white
        zipCodeTextField.attributedPlaceholder = NSAttributedString(string: "Zip Code", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightText])
        
        
        addAddressButton.layer.cornerRadius = 10
        addAddressButton.setTitleColor(AppearanceHelper.ming, for: .normal)
        addAddressButton.backgroundColor = .white
        
        
        let gradient = CAGradientLayer()
        gradient.colors = [AppearanceHelper.macAndCheese.cgColor, AppearanceHelper.begonia.cgColor, AppearanceHelper.turkishRose.cgColor, AppearanceHelper.oldLavender.cgColor, AppearanceHelper.ming.cgColor]
        gradient.frame = view.bounds
        view.layer.insertSublayer(gradient, at: 0)
        
    }
    
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        labelTextField.resignFirstResponder()
        streetTextField.resignFirstResponder()
        cityTextField.resignFirstResponder()
        stateTextField.resignFirstResponder()
        zipCodeTextField.resignFirstResponder()
    }
    
    
    
    
    @IBAction func addAddressPressed(_ sender: Any) {
        
        guard let street = streetTextField.text,
            let city = cityTextField.text,
            let state = stateTextField.text,
            let zipCode = zipCodeTextField.text,
            !street.isEmpty, !city.isEmpty, !state.isEmpty, !zipCode.isEmpty else { return }
        let formattedState = state.uppercased()

        let addressString = "\(street), \(city), \(formattedState) \(zipCode)"
        
        self.addressString = addressString
        
        
        if let label = labelTextField.text {
            self.addressLabel = label
        } else {
            self.addressLabel = street
        }
        
        convertAddress(addressString: addressString)
    }
    
    
    func convertAddress(addressString: String) {
        let geoCoder = CLGeocoder()
        
        geoCoder.geocodeAddressString(addressString, completionHandler: {(placemarks, error) -> Void in
            if let error = error {
                NSLog("Error converting address: \(error)")
            }
            self.newLocation = placemarks?.first?.location
        })
    }
    
    
    func saveAddress() {
        
        guard let label = addressLabel,
            let address = addressString,
            let location = newLocation
            else {
                NSLog("Address Not Valid")
                return
        }
        let radius = radiusSlider.value
        
        addAddressButton.isEnabled = false
        
        animationView.isHidden = false
        animationView.animation = Animation.named("loaderMacAndCheese")
        animationView.loopMode = .loop
        animationView.play()
        
        if let oldAddress = savedAddress {
            
            apiController?.editAddress(id: oldAddress.id ?? 0, label: label, address: address, location: location, shownFireRadius: radius, completion: { (error) in
                if let error = error {
                    NSLog("Error editing address: \(error)")
                    return
                }
                DispatchQueue.main.async {
                    self.animationView.stop()
                    self.animationView.isHidden = true
                    self.addAddressButton.isEnabled = true
                    self.dismiss(animated: true, completion: nil)
                }
            })
            
            
        } else {
            
            apiController?.postAddress(label: label, address: address, location: location, shownFireRadius: radius, completion: { (error) in
                if let error = error {
                    NSLog("Error posting address: \(error)")
                    return
                }
                
                DispatchQueue.main.async {
                    self.animationView.stop()
                    self.animationView.isHidden = true
                    self.addAddressButton.isEnabled = true
                    self.dismiss(animated: true, completion: nil)
                }
            })
        }
    }
    
    
    @IBAction func closeButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func sliderValueChanged(_ sender: Any) {
        sliderValueLabel.text = "\(Int(radiusSlider.value)) miles"
    }
    
    func importAddress() {
        guard let address = savedAddress else { return }
        print(address.address)
        let addressArray = address.address.components(separatedBy: ",")
        var stateZipArray = addressArray.last?.components(separatedBy: " ")
        stateZipArray?.removeFirst()
        
        
        labelTextField.text = address.label ?? ""
        streetTextField.text = addressArray.first ?? ""
        cityTextField.text = addressArray[1]
        stateTextField.text = stateZipArray?.first ?? ""
        zipCodeTextField.text = stateZipArray?.last ?? ""
        addAddressButton.setTitle("Save Address", for: .normal)
        
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
