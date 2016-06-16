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

import UIKit


final class ValetTouchIDTestViewController : UIViewController
{
    // MARK: Properties

    @IBOutlet var textView : UITextView?
    let secureEnclaveValet : VALSecureEnclaveValet
    let username = "CustomerPresentProof"


    // MARK: Initializers

    required init?(coder aDecoder: NSCoder)
    {
        if let valet = VALSecureEnclaveValet(identifier: "UserPresence", accessControl: VALAccessControl.UserPresence) {
            self.secureEnclaveValet = valet
        } else {
            return nil;
        }

        super.init(coder: aDecoder)
    }


    // MARK: Outlets

    @IBAction func setOrUpdateItem(sender: UIResponder)
    {
        let stringToSet = "I am here! " + NSUUID().UUIDString
        let setOrUpdatedItem = secureEnclaveValet.setString(stringToSet, forKey: username)
        updateTextView(#function, (setOrUpdatedItem ? "Success" : "Failure"))
    }

    @IBAction func getItem(sender: UIResponder)
    {
        var userCancelled: ObjCBool = false
        let password = secureEnclaveValet.stringForKey(username, userPrompt: "Use TouchID to retrieve password", userCancelled:&userCancelled)

        var resultString: String
        if (userCancelled) {
            resultString = "user cancelled TouchID"
        } else if (password == nil) {
            resultString = "object not found"
        } else {
            resultString = password as String!
        }

        updateTextView(#function, resultString)
    }

    @IBAction func removeItem(sender: UIResponder)
    {
        let removedItem = secureEnclaveValet.removeObjectForKey(username)
        updateTextView(#function, (removedItem ? "Success" : "Failure"))
    }

    @IBAction func containsItem(sender: UIResponder)
    {
        let containsItem = secureEnclaveValet.containsObjectForKey(username)
        updateTextView(#function, (containsItem ? "YES" : "NO"))
    }


    // MARK: Private

    private func updateTextView(messageComponents: String...)
    {
        if let textView = textView as UITextView! {
            textView.text = textView.text.stringByAppendingFormat("\n%@", messageComponents.joinWithSeparator(" "))
        }
    }
}
