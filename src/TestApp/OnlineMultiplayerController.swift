//
//  OnlineMultiplayerController.swift
//  TestApp
//
//  Created by Jose Torres on 4/11/20.
//  Copyright © 2020 Senior Design. All rights reserved.
//

import UIKit

class OnlineMultiplayerController: UIViewController {

    @IBOutlet weak var notificationLabel: UILabel!
    @IBOutlet weak var gameIDLabel: UILabel!
    @IBOutlet weak var playerLabel: UILabel!
    @IBOutlet weak var hostGameButton: UIButton!
    @IBOutlet weak var joinGameButton: UIButton!
    
    
    
    let urlSession: URLSession = URLSession(configuration: URLSessionConfiguration.default)

    let server: String = "http://server162.site:59435"
    var gameID: Int?
    var didConnect: Bool = false
    var playersInLobby: [String] = ["", "", "", ""]
    var timer = Timer()
    var nameEntered: Bool = false
    var idEntered: Bool = false
    var playerName: String?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.notificationLabel.isHidden = true
    }
    
    @IBAction func enterNameAction(_ sender: Any) {
        let alertController = UIAlertController(title: "Enter Name", message: "Please type in your desired display name", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Enter", style: .default) {
            (_) in
            guard let name = alertController.textFields?[0].text else {
                self.playerName = nil
                return
                
            }
            self.playerLabel.text = "Players: " + name
            self.nameEntered = true
            self.playerName = name
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) {(_) in }
        
        alertController.addTextField {(textField) in
            textField.placeholder = "Enter Name"
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func enterGameIDAction(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Enter the Game ID", message: "Please enter the Game Session ID", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Enter", style: .default){
            (_) in
            guard let id = alertController.textFields?[0].text else{
                self.gameID = nil
                return
            }
            self.gameID = Int(id)
            //print("Game ID is: \(self.gameID)")
            self.gameIDLabel.text = "Game ID: \(self.gameID!)"
            self.idEntered = true
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) {(_) in }
        
        alertController.addTextField{(textField) in
            textField.placeholder = "Enter Game ID"
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    @IBAction func hostGameRequest(_ sender: UIButton) {
        
        if !nameEntered {
            print("No Name was entered")
            return
        }
        
        guard let name = self.playerName else {return}
        
        let endPoint = "/host-request/" + name
        let urlString = server + endPoint
        guard let url = URL(string: urlString) else {return}

        let hostReqTask = urlSession.dataTask(with: url) {
            (data, response, error) in
            if let error = error {
                print(error)
                return
            }
            
            guard let data = data else {return}
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                print(json)

                if let dict = json as? [String: Any] {
                    if let id = dict["gameId"] as? Int {
                        self.gameID = id
                    }
                }
            } catch {
                print("JSON error: \(error.localizedDescription)")
            }

            DispatchQueue.main.async {
                if self.gameID != nil{
                    self.gameIDLabel.text = "GameID is \(self.gameID!)"
                    self.hostGameButton.isEnabled = false
                    self.joinGameButton.isEnabled = false
                    self.timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(self.checkForUpdate), userInfo: nil, repeats: true)
                }

            }
        }

        hostReqTask.resume()
    }
    
    @IBAction func joinGameReq(_ sender: UIButton) {
        guard let gameID = self.gameID else {
            print("Invalid Game ID")
            return
            
        }
        
        guard let name = self.playerName else {
            print("Invalide Name")
            return
        }
        
        let endPoint = "/join/" + String(gameID) + name
        let urlString = server + endPoint
        guard let url = URL(string: urlString) else {return}
        
        let joinReqTask = urlSession.dataTask(with: url) {
            (data, response, error) in
            if let error = error {
                print(error)
                return
            }
            
            guard let data = data else {return}
            do{
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                print(json)
                
                if let dict = json as? [String: Any] {
                    if let confirmation = dict["didConnect"] as? Bool {
                        self.didConnect = confirmation
                    }
                }
            }catch{
                print("JSON error: \(error.localizedDescription)")
            }
            
            DispatchQueue.main.async {
                if self.didConnect {
                    self.joinGameButton.isEnabled = false
                    self.hostGameButton.isEnabled = false
                    self.notificationLabel.text = "Connected to server!"
                    self.timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(self.checkForUpdate), userInfo: nil, repeats: true)
                }
            }
            
        }
        joinReqTask.resume()
    }
    
    
    @objc func checkForUpdate() {
        guard let gameID = self.gameID else{return}
        let endPoint = "/host-check/" + String(gameID)
        guard let url = URL(string: server + endPoint) else {return}
        
        let updateTask = urlSession.dataTask(with: url) {
            (data, response, error) in
            if let error = error {
                print(error)
                return
            }
            guard let data = data else {return}
            do{
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                print(json)
                
                if let dict = json as? [String: Any] {
                    if let name = dict["player1"] as? String {
                        print("Names: \(name)")
                        self.playersInLobby[0] = name
                    } else {
                        print("Didn't work")
                    }
                }
                if let dict = json as? [String: Any] {
                    if let name = dict["player2"] as? String {
                        print("Names: \(name)")
                        self.playersInLobby[1] = name
                    } else {
                        print("Didn't work")
                    }
                }
                if let dict = json as? [String: Any] {
                    if let name = dict["player3"] as? String {
                        print("Names: \(name)")
                        self.playersInLobby[2] = name
                    } else {
                        print("Didn't work")
                    }
                }
            } catch {
                print("JSON error: \(error.localizedDescription)")
            }
            
            DispatchQueue.main.async {
                if !self.playersInLobby.isEmpty {
                    let namesList = self.playersInLobby.joined(separator: ", ")
                    self.playerLabel.text = "Players: " + namesList
                }
            }
        }
        updateTask.resume()
    }
    
}
