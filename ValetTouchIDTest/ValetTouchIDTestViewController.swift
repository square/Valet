//
//  ValetTouchIDTestViewController.swift
//  Valet
//
//  Created by Eric Muller on 4/20/16.
//  Copyright © 2016 Square, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Valet
import UIKit


final class ValetTouchIDTestViewController : UIViewController
{
    // MARK: Properties
    
    @IBOutlet var textView : UITextView?
    var singlePromptSecureEnclaveValet : SinglePromptSecureEnclaveValet
    let username = "CustomerPresentProof"
    
    // MARK: Initializers
    
    required init?(coder aDecoder: NSCoder)
    {
        singlePromptSecureEnclaveValet = SinglePromptSecureEnclaveValet.valet(with: Identifier(nonEmpty: "UserPresence")!, accessControl: .userPresence)
        
        super.init(coder: aDecoder)
    }
    
    // MARK: Outlets
    
    @objc(setOrUpdateItem:)
    @IBAction func setOrUpdateItem(sender: UIResponder)
    {
        let stringToSet = "I am here! " + NSUUID().uuidString
        let setOrUpdatedItem: Bool
        do {
            try singlePromptSecureEnclaveValet.setString(stringToSet, forKey: username)
            setOrUpdatedItem = true
        } catch {
            setOrUpdatedItem = false
        }
        updateTextView(messageComponents: #function, (setOrUpdatedItem ? "Success" : "Failure"))
    }
    
    @objc(getItem:)
    @IBAction func getItem(sender: UIResponder)
    {
        let resultString: String
        do {
            resultString = try singlePromptSecureEnclaveValet.string(forKey: username, withPrompt: "Use TouchID to retrieve password")
        } catch KeychainError.userCancelled {
            resultString = "user cancelled TouchID"
        } catch KeychainError.itemNotFound {
            resultString = "object not found"
        } catch {
            resultString = "caught unknown error \(error)"
        }
        
        updateTextView(messageComponents: #function, resultString)
    }
    
    @objc(removeItem:)
    @IBAction func removeItem(sender: UIResponder)
    {
        let removedItem: Bool
        do {
            try singlePromptSecureEnclaveValet.removeObject(forKey: username)
            removedItem = true
        } catch {
            removedItem = false
        }

        updateTextView(messageComponents: #function, (removedItem ? "Success" : "Failure"))
    }
    
    @objc(containsItem:)
    @IBAction func containsItem(sender: UIResponder)
    {
        let containsItem = singlePromptSecureEnclaveValet.containsObject(forKey: username)
        updateTextView(messageComponents: #function, (containsItem ? "YES" : "NO"))
    }
    
    @objc(requirePrompt:)
    @IBAction func requirePrompt(sender: UIResponder)
    {
        singlePromptSecureEnclaveValet.requirePromptOnNextAccess()
        updateTextView(messageComponents: #function)
    }
    
    // MARK: Private
    
    private func updateTextView(messageComponents: String...)
    {
        if let textView = textView {
            textView.text = textView.text.appendingFormat("\n%@", messageComponents.joined(separator: " "))
        }
    }
}
