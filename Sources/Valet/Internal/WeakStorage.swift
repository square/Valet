//  Created by Dan Federman on 10/10/24.
//  Copyright © 2024 Square, Inc.
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

import Foundation


internal final class WeakStorage<T: AnyObject>: @unchecked Sendable {
    internal subscript(_ key: String) -> T? {
        get {
            lock.withLock {
                identifierToValetMap.object(forKey: key as NSString)
            }
        }
        set {
            lock.withLock {
                identifierToValetMap.setObject(newValue, forKey: key as NSString)
            }
        }
    }

    private let lock = NSLock()
    private let identifierToValetMap = NSMapTable<NSString, T>.strongToWeakObjects()
}
