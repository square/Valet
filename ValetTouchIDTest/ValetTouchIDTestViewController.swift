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
    var singlePromptSecureEnclaveValet : VALSinglePromptSecureEnclaveValet
    let username = "CustomerPresentProof"


    // MARK: Initializers

    required init?(coder aDecoder: NSCoder)
    {
        if let valet = VALSinglePromptSecureEnclaveValet(identifier: "UserPresence", accessControl: VALAccessControl.userPresence) {
            self.singlePromptSecureEnclaveValet = valet
        } else {
            return nil;
        }

        super.init(coder: aDecoder)
    }


    // MARK: Outlets

    @objc(setOrUpdateItem:)
    @IBAction func setOrUpdateItem(sender: UIResponder)
    {
        let stringToSet = "I am here! " + NSUUID().uuidString
        let setOrUpdatedItem = singlePromptSecureEnclaveValet.setString(stringToSet, forKey: username)
        updateTextView(messageComponents: #function, (setOrUpdatedItem ? "Success" : "Failure"))
    }

    @objc(getItem:)
    @IBAction func getItem(sender: UIResponder)
    {
        var userCancelled: ObjCBool = false
        let password = singlePromptSecureEnclaveValet.string(forKey: username, userPrompt: "Use TouchID to retrieve password", userCancelled:&userCancelled)

        var resultString: String
        if (userCancelled.boolValue) {
            resultString = "user cancelled TouchID"
        } else if (password == nil) {
            resultString = "object not found"
        } else {
            resultString = password as String!
        }

        updateTextView(messageComponents: #function, resultString)
    }

    @objc(removeItem:)
    @IBAction func removeItem(sender: UIResponder)
    {
        let removedItem = singlePromptSecureEnclaveValet.removeObject(forKey: username)
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
        if let textView = textView as UITextView! {
            textView.text = textView.text.appendingFormat("\n%@", messageComponents.joined(separator: " "))
        }
    }
}
